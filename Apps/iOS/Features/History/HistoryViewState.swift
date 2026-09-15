import Foundation
import HydrationDomain

public struct HistoryViewState: Equatable, Sendable {
    public struct Row: Equatable, Sendable, Identifiable, Hashable {
        public let id: Date
        public let identifier: String
        public let dayText: String
        public let totalText: String
        public let fraction: Double
        public let accent: SemanticColor
        public let badgeText: String?
        public let isSelected: Bool

        public init(
            id: Date,
            identifier: String,
            dayText: String,
            totalText: String,
            fraction: Double,
            accent: SemanticColor,
            badgeText: String?,
            isSelected: Bool
        ) {
            self.id = id
            self.identifier = identifier
            self.dayText = dayText
            self.totalText = totalText
            self.fraction = fraction
            self.accent = accent
            self.badgeText = badgeText
            self.isSelected = isSelected
        }
    }

    public let title: String
    public let summaryText: String
    public let rows: [Row]
    public let emptyText: String?

    public init(title: String, summaryText: String, rows: [Row], emptyText: String?) {
        self.title = title
        self.summaryText = summaryText
        self.rows = rows
        self.emptyText = emptyText
    }

    public static let placeholder = HistoryViewState(title: "History", summaryText: "", rows: [], emptyText: nil)
}
