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
                WatchTodayScreen(viewModel: makeTodayViewModel())
            }
        }
    }

    // MARK: - Private

    @MainActor
    private func makeTodayViewModel() -> WatchTodayViewModel {
        WatchTodayViewModel(
            fetchProgress: graph.root.makeFetchDay(),
            addDrink: graph.root.makeAddDrink(),
            removeLastDrink: graph.root.makeRemoveLastDrink(),
            mapper: WatchTodayViewDataMapper(calendar: graph.root.calendar, locale: graph.root.locale),
            currentDay: graph.root.makeCurrentDay(),
            changes: graph.root.changes,
            log: graph.root.log
        )
    }
}
#endif
