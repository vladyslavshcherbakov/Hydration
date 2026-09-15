import Foundation
import HydrationDesignSystem
import HydrationDomain

public struct WatchTodayViewState: Equatable, Sendable {
    // MARK: - Situation

    public enum Situation: Equatable, Sendable {
        case loading(Loading)
        case content(Content)
        case failed(Failure)
    }

    // MARK: - Loading

    public struct Loading: Equatable, Sendable {
        public let accessibilityLabel: String

        public init(accessibilityLabel: String) {
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
        public let presets: [Preset]
        public let undoTitle: String
        public let isUndoEnabled: Bool
        public let accessibilityLabel: String

        public init(
            totalText: String,
            goalText: String,
            statusText: String,
            fraction: Double,
            accent: SemanticColor,
            presets: [Preset],
            undoTitle: String,
            isUndoEnabled: Bool,
            accessibilityLabel: String
        ) {
            self.totalText = totalText
            self.goalText = goalText
            self.statusText = statusText
            self.fraction = fraction
            self.accent = accent
            self.presets = presets
            self.undoTitle = undoTitle
            self.isUndoEnabled = isUndoEnabled
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

    // MARK: - Preset

    public struct Preset: Equatable, Sendable, Identifiable, Hashable {
        public let id: Int
        public let title: String
        public let isEnabled: Bool

        public var milliliters: Int { id }

        public init(milliliters: Int, title: String, isEnabled: Bool) {
            self.id = milliliters
            self.title = title
            self.isEnabled = isEnabled
        }
    }

    public let title: String
    public let situation: Situation

    public init(title: String, situation: Situation) {
        self.title = title
        self.situation = situation
    }
}
