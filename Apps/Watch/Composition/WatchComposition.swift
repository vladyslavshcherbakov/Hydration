#if os(watchOS)
import HydrationDomain
import HydrationPairedDevice
import HydrationPersistence
import SwiftUI

@main
struct HydrationWatchApp: App {
    private let root: CompositionRoot
    private let incomingChanges: IncomingDrinkChanges
    private let todaysDrinksSender: TodaysDrinksSender

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
        incomingChanges = IncomingDrinkChanges(localStorage: observedRepository, pairedDevice: pairedDevice, log: log)
        incomingChanges.start()

        let todaysDrinksSender = TodaysDrinksSender(
            repository: observedRepository,
            pairedDevice: pairedDevice,
            currentDay: root.makeCurrentDay(),
            calendar: root.calendar,
            log: log
        )
        self.todaysDrinksSender = todaysDrinksSender
        pairedDevice.whenPairedDeviceBecomesReachable {
            await todaysDrinksSender.sendToPairedDevice()
        }

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
