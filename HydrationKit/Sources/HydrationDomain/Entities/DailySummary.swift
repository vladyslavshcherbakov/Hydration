import Foundation

public struct DailySummary: Equatable, Sendable, Identifiable {
    public let day: Date
    public let total: Volume
    public let goal: HydrationGoal

    public var id: Date { day }

    public init(day: Date, total: Volume, goal: HydrationGoal) {
        self.day = day
        self.total = total
        self.goal = goal
    }

    public var isGoalReached: Bool {
        total >= goal.target
    }

    public var fraction: Double {
        guard goal.target.milliliters > 0 else { return 0 }
        return min(Double(total.milliliters) / Double(goal.target.milliliters), 1.0)
    }
}
