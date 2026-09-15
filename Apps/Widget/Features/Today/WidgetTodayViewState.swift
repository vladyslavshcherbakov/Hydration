import Foundation
import HydrationDesignSystem
import HydrationDomain

public struct WidgetTodayViewState: Equatable, Sendable {
    // MARK: - Situation

    public enum Situation: Equatable, Sendable {
        case content(Content)
        case failed(Failure)
    }

    // MARK: - Content

    public struct Content: Equatable, Sendable {
        public let totalText: String
        public let goalText: String
        public let statusText: String
        public let fraction: Double
        public let accent: SemanticColor
        public let quickAddTitle: String
        public let isQuickAddEnabled: Bool
        public let footnote: String
        public let accessibilityLabel: String

        public init(
            totalText: String,
            goalText: String,
            statusText: String,
            fraction: Double,
            accent: SemanticColor,
            quickAddTitle: String,
            isQuickAddEnabled: Bool,
            footnote: String,
            accessibilityLabel: String
        ) {
            self.totalText = totalText
            self.goalText = goalText
            self.statusText = statusText
            self.fraction = fraction
            self.accent = accent
            self.quickAddTitle = quickAddTitle
            self.isQuickAddEnabled = isQuickAddEnabled
            self.footnote = footnote
            self.accessibilityLabel = accessibilityLabel
        }
    }

    // MARK: - Failure

    public struct Failure: Equatable, Sendable {
        public let message: String
        public let accent: SemanticColor
        public let accessibilityLabel: String

        public init(message: String, accent: SemanticColor, accessibilityLabel: String) {
            self.message = message
            self.accent = accent
            self.accessibilityLabel = accessibilityLabel
        }
    }

    public let title: String
    public let situation: Situation

    public init(title: String, situation: Situation) {
        self.title = title
        self.situation = situation
    }
}

// MARK: - WidgetTodayViewState + CustomStringConvertible

extension WidgetTodayViewState: CustomStringConvertible {
    public var description: String {
        switch situation {
        case .content(let day): return "\(day.totalText) \(day.goalText)"
        case .failed(let failure): return failure.message
        }
    }
}
