import Foundation
import HydrationDomain

@MainActor
public final class WatchTodayViewModel: ObservableObject {
    @Published public private(set) var viewData: WatchTodayViewData

    private let fetchProgress: FetchDayProgressUseCase
    private let addDrink: AddDrinkUseCase
    private let removeLastDrink: RemoveLastDrinkUseCase
    private let mapper: WatchTodayViewDataMapper
    private let currentDay: CurrentDay
    private let calendar: Calendar
    private let changes: DrinkChanges
    private let log: HydrationLog

    // MARK: - Public

    public init(
        fetchProgress: FetchDayProgressUseCase,
        addDrink: AddDrinkUseCase,
        removeLastDrink: RemoveLastDrinkUseCase,
        mapper: WatchTodayViewDataMapper,
        currentDay: CurrentDay,
        calendar: Calendar,
        changes: DrinkChanges,
        log: HydrationLog
    ) {
        self.fetchProgress = fetchProgress
        self.addDrink = addDrink
        self.removeLastDrink = removeLastDrink
        self.mapper = mapper
        self.currentDay = currentDay
        self.calendar = calendar
        self.changes = changes
        self.log = log
        self.viewData = mapper.loading()
    }

    public func observe() async {
        let changeSignals = changes.whenDrinksChange()
        await load()
        for await change in changeSignals {
            let today = currentDay.start()
            guard change.touches(calendar.dayInterval(for: today)) else {
                log.write(.info, "the watch face is staying on \(today), the change was on another day")
                continue
            }
            log.write(.info, "the watch face is reloading, the drinks changed somewhere")
            await load()
        }
    }

    public func load() async {
        await show("loading today") { try await fetchProgress.execute(day: currentDay.start()) }
    }

    public func add(milliliters: Int) async {
        await show("adding \(milliliters) ml") { try await addDrink.execute(milliliters: milliliters, on: currentDay.start()) }
    }

    public func undoLast() async {
        await show("undoing the last drink") { try await removeLastDrink.execute(on: currentDay.start()) }
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
