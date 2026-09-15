import Foundation
import HydrationDesignSystem
import HydrationDomain

public struct DayViewState: Equatable, Sendable {
    // MARK: - Situation

    public enum Situation: Equatable, Sendable {
        case loading(Loading)
        case content(Content)
        case failed(Failure)
    }

    // MARK: - Loading

    public struct Loading: Equatable, Sendable {
        public let message: String
        public let accessibilityLabel: String

        public init(message: String, accessibilityLabel: String) {
            self.message = message
            self.accessibilityLabel = accessibilityLabel
        }
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
        public let entries: [Entry]
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
            entries: [Entry],
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
            self.entries = entries
            self.footnote = footnote
            self.accessibilityLabel = accessibilityLabel
        }
    }

    // MARK: - Failure

    public struct Failure: Equatable, Sendable {
        public let message: String
        public let retryTitle: String
        public let accent: SemanticColor
        public let accessibilityLabel: String

        public init(message: String, retryTitle: String, accent: SemanticColor, accessibilityLabel: String) {
            self.message = message
            self.retryTitle = retryTitle
            self.accent = accent
            self.accessibilityLabel = accessibilityLabel
        }
    }

    // MARK: - Entry

    public struct Entry: Equatable, Sendable, Identifiable, Hashable {
        public let id: UUID
        public let amountText: String
        public let timeText: String

        public init(id: UUID, amountText: String, timeText: String) {
            self.id = id
            self.amountText = amountText
            self.timeText = timeText
        }
    }

    public let title: String
    public let historyTitle: String
    public let situation: Situation

    public init(title: String, historyTitle: String, situation: Situation) {
        self.title = title
        self.historyTitle = historyTitle
        self.situation = situation
    }
}
