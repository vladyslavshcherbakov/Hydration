import Foundation
import HydrationDesignSystem
import HydrationDomain

public struct HistoryViewData: Equatable, Sendable {

    // MARK: - State

    public enum State: Equatable, Sendable {
        case loading
        case content(Content)
        case failed(String)
    }

    // MARK: - Content

    public struct Content: Equatable, Sendable {
        public let summaryText: String
        public let rows: [Row]

        public init(summaryText: String, rows: [Row]) {
            self.summaryText = summaryText
            self.rows = rows
        }
    }

    // MARK: - Row

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
    public let state: State

    public init(title: String, state: State) {
        self.title = title
        self.state = state
    }
}
