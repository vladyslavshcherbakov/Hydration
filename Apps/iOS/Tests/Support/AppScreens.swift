import Foundation
import HydrationDomain
import HydrationRouting
import HydrationTestSupport
@testable import Hydration

extension PersistenceEnvironment {
    var dayPresenter: DayPresenter { DayPresenter(calendar: calendar, locale: locale) }
    var historyPresenter: HistoryPresenter { HistoryPresenter(calendar: calendar, locale: locale, today: today) }
}

@MainActor
extension PersistenceEnvironment {
    func dayScreen(
        day: Date? = nil,
        coordinator: AppCoordinator? = nil,
        repository override: DrinkRepository? = nil
    ) -> DayViewModel {
        DayViewModel(
            day: day ?? today,
            fetchProgress: makeFetchDay(repository: override),
            addDrink: makeAddDrink(repository: override),
            removeDrink: makeRemoveDrink(repository: override),
            presenter: dayPresenter,
            changes: observedRepository,
            log: recordedLog,
            onHistoryRequested: { coordinator?.show(.history) }
        )
    }

    func historyScreen(coordinator: AppCoordinator) -> HistoryViewModel {
        HistoryViewModel(
            fetchHistory: makeFetchHistory(),
            presenter: historyPresenter,
            changes: observedRepository,
            log: recordedLog,
            selectedDay: coordinator.selectedDay,
            onDaySelected: { coordinator.select(day: $0) }
        )
    }

    func deepLinkOpener(coordinator: AppCoordinator) -> DeepLinkOpener {
        DeepLinkOpener(coordinator: coordinator, addDrink: makeAddDrink(), currentDay: makeCurrentDay(), log: recordedLog)
    }
}
