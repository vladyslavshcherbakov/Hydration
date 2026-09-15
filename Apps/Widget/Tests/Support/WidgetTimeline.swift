import Foundation
import HydrationDomain
import HydrationTestSupport

#if canImport(WidgetKit)
import WidgetKit
#endif

enum WidgetStateMismatch: Error {
    case notContent
    case notFailed
}

#if canImport(WidgetKit)
// MARK: - HydrationEntry

extension HydrationEntry {
    var content: WidgetTodayViewData.Content {
        get throws {
            guard case .content(let content) = viewData.state else { throw WidgetStateMismatch.notContent }
            return content
        }
    }

    var failure: WidgetTodayViewData.Failure {
        get throws {
            guard case .failed(let failure) = viewData.state else { throw WidgetStateMismatch.notFailed }
            return failure
        }
    }
}
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
