#if os(iOS)
import HydrationPairedDevice
import HydrationPersistence
import HydrationRouting
import SwiftUI

struct SceneRoot: View {
    @StateObject private var coordinator: AppCoordinator

    @Environment(\.scenePhase) private var scenePhase

    let root: CompositionRoot
    let todaySnapshotSender: TodaySnapshotSender
    let observedDrinks: ObservedDrinkRepository

    init(root: CompositionRoot, todaySnapshotSender: TodaySnapshotSender, observedDrinks: ObservedDrinkRepository) {
        self.root = root
        self.todaySnapshotSender = todaySnapshotSender
        self.observedDrinks = observedDrinks
        _coordinator = StateObject(wrappedValue: AppCoordinator(selectedDay: root.makeCurrentDay().start()))
    }

    var body: some View {
        RootView(coordinator: coordinator, factory: makeFactory())
            .onOpenURL { url in
                Task { await makeDeepLinkOpener().open(url) }
            }
            .onChange(of: scenePhase) { phase in
                guard phase == .active else { return }
                observedDrinks.noteWrittenElsewhere()
                Task { await todaySnapshotSender.sendToPairedDevice() }
            }
    }

    private func makeFactory() -> ScreenFactory {
        ScreenFactory(root: root, coordinator: coordinator)
    }

    private func makeDeepLinkOpener() -> DeepLinkOpener {
        DeepLinkOpener(
            coordinator: coordinator,
            addDrink: root.makeAddDrink(),
            currentDay: root.makeCurrentDay(),
            log: root.log
        )
    }
}
#endif
