#if os(watchOS)
import Foundation
import HydrationDomain
import HydrationPairedDevice
import HydrationPersistence

public struct WatchGraph {
    public let root: CompositionRoot
    public let observedDrinks: ObservedDrinkRepository
    public let incomingChanges: IncomingDrinkChanges

    // MARK: - Public

    public init(
        storage: DrinkRepository & LocalDrinkWriter,
        pairedDevice: PairedDeviceChannel,
        dateProvider: DateProvider,
        calendar: Calendar = .current,
        goal: HydrationGoal = .standard,
        log: HydrationLog
    ) {
        let observedRepository = ObservedDrinkRepository(localStorage: storage)

        observedDrinks = observedRepository
        root = CompositionRoot(
            repository: MirroringDrinkRepository(localStorage: observedRepository, pairedDevice: pairedDevice),
            changes: observedRepository,
            log: log,
            dateProvider: dateProvider,
            calendar: calendar,
            goal: goal
        )
        incomingChanges = IncomingDrinkChanges(
            localStorage: observedRepository,
            pairedDevice: pairedDevice,
            calendar: root.calendar,
            log: log
        )

        incomingChanges.start()
    }

    @MainActor
    public func makeTodayViewModel() -> WatchTodayViewModel {
        WatchTodayViewModel(
            fetchProgress: root.makeFetchDay(),
            addDrink: root.makeAddDrink(),
            removeLastDrink: root.makeRemoveLastDrink(),
            mapper: WatchTodayViewDataMapper(calendar: root.calendar, locale: root.locale),
            currentDay: root.makeCurrentDay(),
            calendar: root.calendar,
            changes: root.changes,
            log: root.log
        )
    }
}
#endif
