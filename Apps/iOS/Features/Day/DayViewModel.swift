import Foundation
import HydrationDomain

@MainActor
public final class DayViewModel: ObservableObject {
    @Published public private(set) var viewData: DayViewData

    private let day: Date
    private let fetchProgress: FetchDayProgressUseCase
    private let addDrink: AddDrinkUseCase
    private let removeDrink: RemoveDrinkUseCase
    private let mapper: DayViewDataMapper
    private let changes: DrinkChanges
    private let log: HydrationLog
    private let onHistoryRequested: () -> Void

    // MARK: - Public

    public init(
        day: Date,
        fetchProgress: FetchDayProgressUseCase,
        addDrink: AddDrinkUseCase,
        removeDrink: RemoveDrinkUseCase,
        mapper: DayViewDataMapper,
        changes: DrinkChanges,
        log: HydrationLog,
        onHistoryRequested: @escaping () -> Void
    ) {
        self.day = day
        self.fetchProgress = fetchProgress
        self.addDrink = addDrink
        self.removeDrink = removeDrink
        self.mapper = mapper
        self.changes = changes
        self.log = log
        self.onHistoryRequested = onHistoryRequested
        self.viewData = mapper.loading()
    }

    public func observe() async {
        let changeSignals = changes.whenDrinksChange()
        await load()
        for await _ in changeSignals {
            log.write(.info, "the day screen is reloading, the drinks changed somewhere")
            await load()
        }
    }

    public func load() async {
        await show("loading the day") { try await fetchProgress.execute(day: day) }
    }

    public func quickAdd(milliliters: Int = Volume.quickAdd.milliliters) async {
        await show("adding \(milliliters) ml") { try await addDrink.execute(milliliters: milliliters, on: day) }
    }

    public func remove(entryID: UUID) async {
        await show("removing the drink \(entryID)") { try await removeDrink.execute(id: entryID, on: day) }
    }

    public func openHistory() {
        onHistoryRequested()
    }

    // MARK: - Private

    private func show(_ attemptDescription: String, _ loadProgress: () async throws -> DailyProgress) async {
        do {
            let progress = try await loadProgress()
            log.write(.info, "\(attemptDescription): \(progress.day) now holds \(progress.total.milliliters) ml")
            viewData = mapper.viewData(for: progress)
        } catch {
            log.write(.error, "\(attemptDescription) failed: \(error)")
            viewData = mapper.viewData(for: error)
        }
    }
}
