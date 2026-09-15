import Foundation
import HydrationDesignSystem
import HydrationDomain

public struct DayViewState: Equatable, Sendable {

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
    public let totalText: String
    public let goalText: String
    public let statusText: String
    public let fraction: Double
    public let accent: SemanticColor
    public let quickAddTitle: String
    public let isQuickAddEnabled: Bool
    public let historyTitle: String
    public let entries: [Entry]
    public let footnote: String?
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
        historyTitle: String,
        entries: [Entry],
        footnote: String?,
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
        self.historyTitle = historyTitle
        self.entries = entries
        self.footnote = footnote
        self.accessibilityLabel = accessibilityLabel
    }
}
