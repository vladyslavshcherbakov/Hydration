import Foundation
import HydrationDomain

@MainActor
public final class HistoryViewModel: ObservableObject {
    public static let visibleDays = 14

    @Published public private(set) var state: HistoryViewState = .placeholder

    public var onStateChange: ((HistoryViewState) -> Void)?

    private let fetchHistory: FetchHistoryUseCase
    private let presenter: HistoryPresenter
    private let changes: DrinkChanges
    private let log: HydrationLog
    private let onDaySelected: (Date) -> Void

    private var summaries: [DailySummary] = []
    private var selectedDay: Date
    private var didLoad = false

    public init(
        fetchHistory: FetchHistoryUseCase,
        presenter: HistoryPresenter,
        changes: DrinkChanges,
        log: HydrationLog,
        selectedDay: Date,
        onDaySelected: @escaping (Date) -> Void
    ) {
        self.fetchHistory = fetchHistory
        self.presenter = presenter
        self.changes = changes
        self.log = log
        self.selectedDay = selectedDay
        self.onDaySelected = onDaySelected
    }

    public func observe() async {
        let changeSignals = changes.whenDrinksChange()
        await load()
        for await _ in changeSignals {
            await load()
        }
    }

    public func load() async {
        do {
            summaries = try await fetchHistory.execute(days: HistoryViewModel.visibleDays)
            didLoad = true
            render()
        } catch {
            log.write(.error, "loading the last \(HistoryViewModel.visibleDays) days failed: \(error)")
            summaries = []
            didLoad = false
            publish(presenter.present(error: error))
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

    private func render() {
        publish(presenter.present(summaries: summaries, selected: selectedDay))
    }

    private func publish(_ newState: HistoryViewState) {
        state = newState
        onStateChange?(newState)
    }
}
