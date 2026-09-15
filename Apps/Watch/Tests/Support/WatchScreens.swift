import Foundation
import HydrationDomain
import HydrationTestSupport
@testable import HydrationWatch

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
