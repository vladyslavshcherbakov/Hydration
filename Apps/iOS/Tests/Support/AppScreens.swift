import Foundation
import HydrationDomain
import HydrationRouting
import HydrationTestSupport
@testable import Hydration

// MARK: - AppGraphEnvironment

extension AppGraphEnvironment {
    var dayMapper: DayViewDataMapper { DayViewDataMapper(calendar: calendar, locale: locale) }
    var historyMapper: HistoryViewDataMapper { HistoryViewDataMapper(calendar: calendar, locale: locale, today: today) }
}

// MARK: - AppGraphEnvironment

@MainActor
extension AppGraphEnvironment {
    func dayScreen(day: Date? = nil, coordinator: AppCoordinator? = nil) -> DayViewModel {
        DayViewModel(
            day: day ?? today,
            fetchProgress: graph.root.makeFetchDay(),
            addDrink: graph.root.makeAddDrink(),
            removeDrink: graph.root.makeRemoveDrink(),
            mapper: dayMapper,
            calendar: calendar,
            changes: graph.root.changes,
            log: silentLog,
            onHistoryRequested: { coordinator?.show(.history) }
        )
    }

    func historyScreen(coordinator: AppCoordinator) -> HistoryViewModel {
        HistoryViewModel(
            fetchHistory: graph.root.makeFetchHistory(),
            mapper: historyMapper,
            changes: graph.root.changes,
            log: silentLog,
            selectedDay: coordinator.selectedDay,
            onDaySelected: { coordinator.select(day: $0) }
        )
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
