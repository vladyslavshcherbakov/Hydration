import Foundation
import HydrationDomain
import HydrationRouting
import HydrationTestSupport
@testable import Hydration

// MARK: - AppGraphEnvironment

@MainActor
extension AppGraphEnvironment {
    func screenFactory(coordinator: AppCoordinator) -> ScreenFactory {
        ScreenFactory(root: graph.root, coordinator: coordinator)
    }

    func dayScreen(day: Date? = nil, coordinator: AppCoordinator? = nil) -> DayViewModel {
        let coordinator = coordinator ?? AppCoordinator(selectedDay: day ?? today)
        return screenFactory(coordinator: coordinator).makeDayViewModel()
    }

    func historyScreen(coordinator: AppCoordinator) -> HistoryViewModel {
        screenFactory(coordinator: coordinator).makeHistoryViewModel()
    }

    func deepLinkOpener(coordinator: AppCoordinator) -> DeepLinkOpener {
        DeepLinkOpener(
            coordinator: coordinator,
            addDrink: graph.root.makeAddDrink(),
            currentDay: graph.root.makeCurrentDay(),
            log: silentLog
        )
    }
}
