import Foundation
@testable import HydrationWatch

enum ScreenStateMismatch: Error {
    case notContent
    case notFailed
}

// MARK: - WatchTodayViewModel

@MainActor
extension WatchTodayViewModel {
    var content: WatchTodayViewData.Content {
        get throws {
            guard case .content(let content) = viewData.state else { throw ScreenStateMismatch.notContent }
            return content
        }
    }

    var failure: WatchTodayViewData.Failure {
        get throws {
            guard case .failed(let failure) = viewData.state else { throw ScreenStateMismatch.notFailed }
            return failure
        }
    }
}
