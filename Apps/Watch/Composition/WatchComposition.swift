#if os(watchOS)
import HydrationDomain
import HydrationPairedDevice
import HydrationPersistence
import SwiftUI

@main
struct HydrationWatchApp: App {
    private let graph: WatchGraph

    // MARK: - Public

    init() {
        let log = ConsoleLog(category: "hydration-watch")
        let coreDataStack = CoreDataStack.forLaunch(
            appGroup: AppGroup.identifier,
            arguments: ProcessInfo.processInfo.arguments
        )

        graph = WatchGraph(
            storage: CoreDataDrinkRepository(coreDataStack: coreDataStack, log: log),
            pairedDevice: WatchConnectivityChannel.forThisDevice(log: log),
            dateProvider: SystemDateProvider(),
            log: log
        )

        log.write(
            .info,
            "the watch app started, store at \(coreDataStack.storeURL?.path ?? "an unknown path")"
        )
    }

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                WatchTodayScreen(viewModel: graph.makeTodayViewModel())
            }
        }
    }
}
#endif
