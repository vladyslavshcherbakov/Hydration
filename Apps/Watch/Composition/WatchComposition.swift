#if os(watchOS)
import HydrationDomain
import HydrationPairedDevice
import HydrationPersistence
import SwiftUI

@main
struct HydrationWatchApp: App {
    private let root: CompositionRoot
    private let incomingChanges: IncomingDrinkChanges

    // MARK: - Public

    init() {
        let log = ConsoleLog(category: "hydration-watch")
        let coreDataStack = CoreDataStack.forLaunch(
            appGroup: AppGroup.identifier,
            arguments: ProcessInfo.processInfo.arguments
        )
        let observedRepository = ObservedDrinkRepository(localStorage: CoreDataDrinkRepository(coreDataStack: coreDataStack, log: log))
        let pairedDevice: PairedDeviceChannel = WatchConnectivityChannel(log: log) ?? NoPairedDeviceChannel()

        root = CompositionRoot(
            repository: MirroringDrinkRepository(localStorage: observedRepository, pairedDevice: pairedDevice),
            changes: observedRepository,
            log: log,
            dateProvider: SystemDateProvider()
        )
        incomingChanges = IncomingDrinkChanges(
            localStorage: observedRepository,
            pairedDevice: pairedDevice,
            calendar: root.calendar,
            log: log
        )
        incomingChanges.start()

        log.write(
            .info,
            "the watch app started, store at \(coreDataStack.storeURL?.path ?? "an unknown path"), paired device link is \(type(of: pairedDevice))"
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
            fetchProgress: root.makeFetchDay(),
            addDrink: root.makeAddDrink(),
            removeLastDrink: root.makeRemoveLastDrink(),
            presenter: WatchTodayPresenter(calendar: root.calendar, locale: root.locale),
            currentDay: root.makeCurrentDay(),
            changes: root.changes,
            log: root.log
        )
    }
}
#endif
