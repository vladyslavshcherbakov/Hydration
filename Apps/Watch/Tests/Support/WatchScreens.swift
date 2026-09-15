import Foundation
import HydrationDomain
import HydrationTestSupport
@testable import HydrationWatch

extension PersistenceEnvironment {
    var watchPresenter: WatchTodayPresenter { WatchTodayPresenter(calendar: calendar, locale: locale) }
}

@MainActor
extension PersistenceEnvironment {
    func todayScreen(repository override: DrinkRepository? = nil) -> WatchTodayViewModel {
        WatchTodayViewModel(
            fetchProgress: makeFetchDay(repository: override),
            addDrink: makeAddDrink(repository: override),
            removeLastDrink: makeRemoveLast(repository: override),
            presenter: watchPresenter,
            currentDay: makeCurrentDay(),
            changes: observedRepository,
            log: recordedLog
        )
    }
}
