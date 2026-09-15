#if os(iOS)
import Foundation
import HydrationDomain
import HydrationPairedDevice
import HydrationPersistence

public struct AppGraph {
    public let root: CompositionRoot
    public let observedDrinks: ObservedDrinkRepository
    public let incomingChanges: IncomingDrinkChanges
    public let todaySnapshotSender: TodaySnapshotSender

    // MARK: - Public

    public init(
        storage: DrinkRepository & LocalDrinkWriter,
        pairedDevice: PairedDeviceChannel,
        reloadWidget: @escaping @Sendable () async -> Void,
        dateProvider: DateProvider,
        calendar: Calendar = .current,
        goal: HydrationGoal = .standard,
        log: HydrationLog
    ) {
        let observedRepository = ObservedDrinkRepository(localStorage: storage)
        let localWrites = WidgetRefreshingDrinkRepository(localStorage: observedRepository, onWrite: reloadWidget)

        observedDrinks = observedRepository
        root = CompositionRoot(
            repository: MirroringDrinkRepository(localStorage: localWrites, pairedDevice: pairedDevice),
            changes: observedRepository,
            log: log,
            dateProvider: dateProvider,
            calendar: calendar,
            goal: goal
        )
        incomingChanges = IncomingDrinkChanges(
            localStorage: localWrites,
            pairedDevice: pairedDevice,
            calendar: root.calendar,
            log: log
        )
        todaySnapshotSender = TodaySnapshotSender(
            repository: localWrites,
            pairedDevice: pairedDevice,
            currentDay: root.makeCurrentDay(),
            calendar: root.calendar,
            log: log
        )

        incomingChanges.start()
        let sender = todaySnapshotSender
        pairedDevice.whenPairedDeviceBecomesReachable {
            await sender.sendToPairedDevice()
        }
    }
}
#endif
