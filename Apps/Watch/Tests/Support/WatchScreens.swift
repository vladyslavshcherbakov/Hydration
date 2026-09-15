import Foundation
import HydrationDomain
import HydrationTestSupport
@testable import HydrationWatch

enum WatchScreenStateMismatch: Error {
    case notContent
    case notFailed
}

// MARK: - WatchTodayViewModel
@MainActor
extension WatchTodayViewModel {
    var content: WatchTodayViewState.Content {
        get throws {
            guard case .content(let content) = state.situation else { throw WatchScreenStateMismatch.notContent }
            return content
        }
    }

    var failure: WatchTodayViewState.Failure {
        get throws {
            guard case .failed(let failure) = state.situation else { throw WatchScreenStateMismatch.notFailed }
            return failure
        }
    }
}

// MARK: - PersistenceEnvironment
extension PersistenceEnvironment {
    var watchPresenter: WatchTodayPresenter { WatchTodayPresenter(calendar: calendar, locale: locale) }
}

@MainActor

// MARK: - PersistenceEnvironment
extension PersistenceEnvironment {
    func todayScreen(repository override: DrinkRepository? = nil) -> WatchTodayViewModel {
        WatchTodayViewModel(
            fetchProgress: makeFetchDay(repository: override),
            addDrink: makeAddDrink(repository: override),
            removeLastDrink: makeRemoveLast(repository: override),
            presenter: watchPresenter,
            currentDay: makeCurrentDay(),
            changes: observedRepository,
            log: silentLog
        )
    }
}
