#if os(iOS)
import HydrationDomain
import HydrationPairedDevice
import HydrationPersistence
import SwiftUI

@main
struct HydrationApp: App {
    private let graph: AppGraph

    // MARK: - Public

    init() {
        let log = ConsoleLog(category: "hydration")
        let coreDataStack = CoreDataStack.forLaunch(
            appGroup: AppGroup.identifier,
            arguments: ProcessInfo.processInfo.arguments
        )
        let widgetRefresh = WidgetRefresh(log: log)

        graph = AppGraph(
            storage: CoreDataDrinkRepository(coreDataStack: coreDataStack, log: log),
            pairedDevice: WatchConnectivityChannel.forThisDevice(log: log),
            reloadWidget: { await widgetRefresh.reload() },
            dateProvider: SystemDateProvider(),
            log: log
        )

        log.write(
            .info,
            "the phone app started, sharing \(AppGroup.identifier), store at \(coreDataStack.storeURL?.path ?? "an unknown path")"
        )
    }

    var body: some Scene {
        WindowGroup {
            SceneRoot(
                root: graph.root,
                todaySnapshotSender: graph.todaySnapshotSender,
                observedDrinks: graph.observedDrinks
            )
        }
    }
}
#endif
