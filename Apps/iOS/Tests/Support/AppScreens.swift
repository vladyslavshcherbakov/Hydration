import Foundation
import HydrationDomain
import HydrationRouting
import HydrationTestSupport
@testable import Hydration

enum ScreenStateMismatch: Error {
    case notLoading
    case notContent
    case notFailed
}

// MARK: - DayViewModel

@MainActor
extension DayViewModel {
    var content: DayViewData.Content {
        get throws {
            guard case .content(let content) = viewData.state else { throw ScreenStateMismatch.notContent }
            return content
        }
    }

    var failure: DayViewData.Failure {
        get throws {
            guard case .failed(let failure) = viewData.state else { throw ScreenStateMismatch.notFailed }
            return failure
        }
    }
}

// MARK: - PersistenceEnvironment

extension PersistenceEnvironment {
    var dayMapper: DayViewDataMapper { DayViewDataMapper(calendar: calendar, locale: locale) }
    var historyPresenter: HistoryPresenter { HistoryPresenter(calendar: calendar, locale: locale, today: today) }
}

// MARK: - PersistenceEnvironment

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
            mapper: dayMapper,
            changes: observedRepository,
            log: silentLog,
            onHistoryRequested: { coordinator?.show(.history) }
        )
    }

    func historyScreen(coordinator: AppCoordinator) -> HistoryViewModel {
        HistoryViewModel(
            fetchHistory: makeFetchHistory(),
            presenter: historyPresenter,
            changes: observedRepository,
            log: silentLog,
            selectedDay: coordinator.selectedDay,
            onDaySelected: { coordinator.select(day: $0) }
        )
    }

    func deepLinkOpener(coordinator: AppCoordinator) -> DeepLinkOpener {
        DeepLinkOpener(coordinator: coordinator, addDrink: makeAddDrink(), currentDay: makeCurrentDay(), log: silentLog)
    }
}
