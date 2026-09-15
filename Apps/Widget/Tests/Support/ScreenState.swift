import Foundation

#if canImport(WidgetKit)
enum ScreenStateMismatch: Error {
    case notContent
    case notFailed
}

// MARK: - HydrationEntry

extension HydrationEntry {
    var content: WidgetTodayViewData.Content {
        get throws {
            guard case .content(let content) = viewData.state else { throw ScreenStateMismatch.notContent }
            return content
        }
    }

    var failure: WidgetTodayViewData.Failure {
        get throws {
            guard case .failed(let failure) = viewData.state else { throw ScreenStateMismatch.notFailed }
            return failure
        }
    }
}
#endif
