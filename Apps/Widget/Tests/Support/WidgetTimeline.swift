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
    var content: WidgetTodayViewState.Content {
        get throws {
            guard case .content(let content) = state.situation else { throw WidgetStateMismatch.notContent }
            return content
        }
    }

    var failure: WidgetTodayViewState.Failure {
        get throws {
            guard case .failed(let failure) = state.situation else { throw WidgetStateMismatch.notFailed }
            return failure
        }
    }
}
#endif

// MARK: - PersistenceEnvironment
extension PersistenceEnvironment {
    var widgetPresenter: WidgetTodayPresenter { WidgetTodayPresenter(calendar: calendar, locale: locale) }

    #if canImport(WidgetKit)
    func widgetTimeline(repository override: DrinkRepository? = nil) -> HydrationTimelineProvider {
        HydrationTimelineProvider(
            fetchProgress: makeFetchDay(repository: override),
            presenter: widgetPresenter,
            dateProvider: dateProvider,
            currentDay: makeCurrentDay(),
            log: silentLog
        )
    }
    #endif
}
