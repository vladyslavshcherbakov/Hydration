import Foundation
import HydrationDomain
import HydrationTestSupport

#if canImport(WidgetKit)
import WidgetKit
#endif

// MARK: - PersistenceEnvironment

extension PersistenceEnvironment {
    var widgetMapper: WidgetTodayViewDataMapper { WidgetTodayViewDataMapper(calendar: calendar, locale: locale) }

    #if canImport(WidgetKit)
    func widgetTimeline(repository override: DrinkRepository? = nil) -> HydrationTimelineProvider {
        HydrationTimelineProvider(
            fetchProgress: makeFetchDay(repository: override),
            mapper: widgetMapper,
            dateProvider: dateProvider,
            currentDay: makeCurrentDay(),
            log: silentLog
        )
    }
    #endif
}
