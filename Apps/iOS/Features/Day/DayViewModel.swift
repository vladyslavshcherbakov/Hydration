import Foundation
import HydrationDomain

@MainActor
public final class DayViewModel: ObservableObject {
    @Published public private(set) var viewData: DayViewData
    @Published public private(set) var notice: String?

    private let day: Date
    private let fetchProgress: FetchDayProgressUseCase
    private let addDrink: AddDrinkUseCase
    private let removeDrink: RemoveDrinkUseCase
    private let mapper: DayViewDataMapper
    private let calendar: Calendar
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
        calendar: Calendar,
        changes: DrinkChanges,
        log: HydrationLog,
        onHistoryRequested: @escaping () -> Void
    ) {
        self.day = day
        self.fetchProgress = fetchProgress
        self.addDrink = addDrink
        self.removeDrink = removeDrink
        self.mapper = mapper
        self.calendar = calendar
        self.changes = changes
        self.log = log
        self.onHistoryRequested = onHistoryRequested
        self.viewData = mapper.loading()
    }

    public func observe() async {
        let changeSignals = changes.whenDrinksChange()
        await load()
        for await change in changeSignals {
            guard change.touches(calendar.dayInterval(for: day)) else {
                log.write(.info, "the day screen is staying on \(day), the change was on another day")
                continue
            }
            log.write(.info, "the day screen is reloading, the drinks changed somewhere")
            await load()
        }
    }

    public func load() async {
        do {
            show(try await fetchProgress.execute(day: day), after: "loading the day")
        } catch {
            log.write(.error, "loading the day failed: \(error)")
            viewData = mapper.viewData(for: error)
        }
    }

    public func quickAdd(milliliters: Int = Volume.quickAdd.milliliters) async {
        await attempt("adding \(milliliters) ml") { try await addDrink.execute(milliliters: milliliters, on: day) }
    }

    public func remove(entryID: UUID) async {
        await attempt("removing the drink \(entryID)") { try await removeDrink.execute(id: entryID, on: day) }
    }

    public func dismissNotice() {
        notice = nil
    }

    public func openHistory() {
        onHistoryRequested()
    }

    // MARK: - Private

    private func attempt(_ attemptDescription: String, _ change: () async throws -> DailyProgress) async {
        do {
            show(try await change(), after: attemptDescription)
        } catch {
            log.write(.error, "\(attemptDescription) failed, the day stays as it is: \(error)")
            notice = mapper.notice(for: error)
        }
    }

    private func show(_ progress: DailyProgress, after attemptDescription: String) {
        log.write(.info, "\(attemptDescription): \(progress.day) now holds \(progress.total.milliliters) ml")
        viewData = mapper.viewData(for: progress)
        notice = nil
    }
}
