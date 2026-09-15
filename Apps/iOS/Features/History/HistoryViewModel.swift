import Foundation
import HydrationDomain

@MainActor
public final class HistoryViewModel: ObservableObject {
    public static let visibleDays = 14

    @Published public private(set) var viewData: HistoryViewData

    public var onViewDataChange: ((HistoryViewData) -> Void)?

    private let fetchHistory: FetchHistoryUseCase
    private let mapper: HistoryViewDataMapper
    private let changes: DrinkChanges
    private let log: HydrationLog
    private let onDaySelected: (Date) -> Void

    private var summaries: [DailySummary] = []
    private var selectedDay: Date
    private var didLoad = false

    // MARK: - Public

    public init(
        fetchHistory: FetchHistoryUseCase,
        mapper: HistoryViewDataMapper,
        changes: DrinkChanges,
        log: HydrationLog,
        selectedDay: Date,
        onDaySelected: @escaping (Date) -> Void
    ) {
        self.fetchHistory = fetchHistory
        self.mapper = mapper
        self.changes = changes
        self.log = log
        self.selectedDay = selectedDay
        self.onDaySelected = onDaySelected
        self.viewData = mapper.loading()
    }

    public func observe() async {
        let changeSignals = changes.whenDrinksChange()
        await load()
        for await _ in changeSignals {
            log.write(.info, "history is reloading, the drinks changed somewhere")
            await load()
        }
    }

    public func load() async {
        do {
            summaries = try await fetchHistory.execute(days: HistoryViewModel.visibleDays)
            didLoad = true
            log.write(.info, "history read \(HistoryViewModel.visibleDays) days, \(daysWithDrinks) of them with drinks")
            render()
        } catch {
            log.write(.error, "loading the last \(HistoryViewModel.visibleDays) days failed: \(error)")
            summaries = []
            didLoad = false
            publish(mapper.viewData(for: error))
        }
    }

    public func select(rowID: Date) {
        onDaySelected(rowID)
        apply(selected: rowID)
    }

    public func apply(selected day: Date) {
        guard selectedDay != day else { return }
        selectedDay = day
        guard didLoad else { return }
        render()
    }

    // MARK: - Private

    private var daysWithDrinks: Int {
        summaries.filter { $0.total > .zero }.count
    }

    private func render() {
        publish(mapper.viewData(for: summaries, selected: selectedDay))
    }

    private func publish(_ newViewData: HistoryViewData) {
        viewData = newViewData
        onViewDataChange?(newViewData)
    }
}
