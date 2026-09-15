import Foundation
import HydrationDomain

@MainActor
public final class DayViewModel: ObservableObject {
    @Published public private(set) var state: DayViewState

    private let day: Date
    private let fetchProgress: FetchDayProgressUseCase
    private let addDrink: AddDrinkUseCase
    private let removeDrink: RemoveDrinkUseCase
    private let presenter: DayPresenter
    private let changes: DrinkChanges
    private let log: HydrationLog
    private let onHistoryRequested: () -> Void

    public init(
        day: Date,
        fetchProgress: FetchDayProgressUseCase,
        addDrink: AddDrinkUseCase,
        removeDrink: RemoveDrinkUseCase,
        presenter: DayPresenter,
        changes: DrinkChanges,
        log: HydrationLog,
        onHistoryRequested: @escaping () -> Void
    ) {
        self.day = day
        self.fetchProgress = fetchProgress
        self.addDrink = addDrink
        self.removeDrink = removeDrink
        self.presenter = presenter
        self.changes = changes
        self.log = log
        self.onHistoryRequested = onHistoryRequested
        self.state = presenter.presentLoading()
    }

    public func observe() async {
        let changeSignals = changes.whenDrinksChange()
        await load()
        for await _ in changeSignals {
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

    private func show(_ attemptDescription: String, _ loadProgress: () async throws -> DailyProgress) async {
        do {
            state = presenter.present(progress: try await loadProgress())
        } catch {
            log.write(.error, "\(attemptDescription) failed: \(error)")
            state = presenter.present(error: error)
        }
    }
}
