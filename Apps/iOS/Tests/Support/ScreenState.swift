import Foundation
@testable import Hydration

enum ScreenStateMismatch: Error {
    case notContent
    case notFailed
}

// MARK: - DayViewModel

@MainActor
extension DayViewModel {
    var content: DayViewData.Content {
        get throws {
            guard case .content(let content) = viewData.state else { throw ScreenStateMismatch.notContent }
            return content
        }
    }

    var failure: DayViewData.Failure {
        get throws {
            guard case .failed(let failure) = viewData.state else { throw ScreenStateMismatch.notFailed }
            return failure
        }
    }
}

// MARK: - HistoryViewModel

@MainActor
extension HistoryViewModel {
    var content: HistoryViewData.Content {
        get throws {
            guard case .content(let content) = viewData.state else { throw ScreenStateMismatch.notContent }
            return content
        }
    }

    var failure: String {
        get throws {
            guard case .failed(let message) = viewData.state else { throw ScreenStateMismatch.notFailed }
            return message
        }
    }
}
