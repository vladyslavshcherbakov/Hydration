import Foundation
import HydrationDomain
import HydrationTestSupport
@testable import HydrationWatch

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
