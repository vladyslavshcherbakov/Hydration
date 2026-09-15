#if os(iOS)
import HydrationDomain
import HydrationPairedDevice
import HydrationPersistence
import SwiftUI

@main
struct HydrationApp: App {
    private let root: CompositionRoot
    private let incomingChanges: IncomingDrinkChanges
    private let todaySnapshotSender: TodaySnapshotSender
    private let observedDrinks: ObservedDrinkRepository

    init() {
        let log = ConsoleLog(category: "hydration")
        let coreDataStack = CoreDataStack.forLaunch(
            appGroup: AppGroup.identifier,
            arguments: ProcessInfo.processInfo.arguments
        )
        let widgetRefresh = WidgetRefresh(log: log)
        let observedRepository = ObservedDrinkRepository(localStorage: CoreDataDrinkRepository(coreDataStack: coreDataStack, log: log))
        let widgetRefreshingRepository = WidgetRefreshingDrinkRepository(
            localStorage: observedRepository,
            onWrite: { await widgetRefresh.reload() }
        )
        let pairedDevice: PairedDeviceChannel = WatchConnectivityChannel(log: log) ?? NoPairedDeviceChannel()

        observedDrinks = observedRepository
        root = CompositionRoot(
            repository: MirroringDrinkRepository(localStorage: widgetRefreshingRepository, pairedDevice: pairedDevice),
            changes: observedRepository,
            log: log,
            dateProvider: SystemDateProvider()
        )
        incomingChanges = IncomingDrinkChanges(
            localStorage: widgetRefreshingRepository,
            pairedDevice: pairedDevice,
            calendar: root.calendar,
            log: log
        )
        incomingChanges.start()

        let todaySnapshotSender = TodaySnapshotSender(
            repository: widgetRefreshingRepository,
            pairedDevice: pairedDevice,
            currentDay: root.makeCurrentDay(),
            calendar: root.calendar,
            log: log
        )
        self.todaySnapshotSender = todaySnapshotSender
        pairedDevice.whenPairedDeviceBecomesReachable {
            await todaySnapshotSender.sendToPairedDevice()
        }

        log.write(
            .info,
            "the phone app started, sharing \(AppGroup.identifier), store at \(coreDataStack.storeURL?.path ?? "an unknown path"), paired device link is \(type(of: pairedDevice))"
        )
    }

    var body: some Scene {
        WindowGroup {
            SceneRoot(root: root, todaySnapshotSender: todaySnapshotSender, observedDrinks: observedDrinks)
        }
    }
}
#endif
