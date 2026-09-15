import Foundation
import HydrationDomain
import HydrationTestSupport

#if canImport(WidgetKit)
import WidgetKit
#endif

extension PersistenceEnvironment {
    var widgetPresenter: WidgetTodayPresenter { WidgetTodayPresenter(calendar: calendar, locale: locale) }

    #if canImport(WidgetKit)
    func widgetTimeline(repository override: DrinkRepository? = nil) -> HydrationTimelineProvider {
        HydrationTimelineProvider(
            fetchProgress: makeFetchDay(repository: override),
            presenter: widgetPresenter,
            dateProvider: dateProvider,
            currentDay: makeCurrentDay(),
            log: recordedLog
        )
    }
    #endif
}
