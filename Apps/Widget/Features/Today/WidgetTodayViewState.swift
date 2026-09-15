import Foundation
import HydrationDomain

public struct WidgetTodayViewState: Equatable, Sendable {
    public let title: String
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
        title: String,
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
        self.title = title
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
