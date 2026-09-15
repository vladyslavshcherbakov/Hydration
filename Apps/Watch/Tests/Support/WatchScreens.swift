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
    var content: WatchTodayViewData.Content {
        get throws {
            guard case .content(let content) = viewData.state else { throw WatchScreenStateMismatch.notContent }
            return content
        }
    }

    var failure: WatchTodayViewData.Failure {
        get throws {
            guard case .failed(let failure) = viewData.state else { throw WatchScreenStateMismatch.notFailed }
            return failure
        }
    }
}

// MARK: - PersistenceEnvironment

extension PersistenceEnvironment {
    var watchMapper: WatchTodayViewDataMapper { WatchTodayViewDataMapper(calendar: calendar, locale: locale) }
}

// MARK: - PersistenceEnvironment

@MainActor
extension PersistenceEnvironment {
    func todayScreen(repository override: DrinkRepository? = nil) -> WatchTodayViewModel {
        WatchTodayViewModel(
            fetchProgress: makeFetchDay(repository: override),
            addDrink: makeAddDrink(repository: override),
            removeLastDrink: makeRemoveLast(repository: override),
            mapper: watchMapper,
            currentDay: makeCurrentDay(),
            changes: observedRepository,
            log: silentLog
        )
    }
}
