import Foundation

public struct DailyProgress: Equatable, Sendable {
    public static let activeDayStartHour = 8
    public static let activeDayEndHour = 22
    public static let excessiveMultiplier = 1.5

    public let day: Date
    public let goal: HydrationGoal
    public let entries: [DrinkEntry]
    public let evaluatedAt: Date
    public let calendar: Calendar

    public init(day: Date, goal: HydrationGoal, entries: [DrinkEntry], evaluatedAt: Date, calendar: Calendar) {
        self.day = day
        self.goal = goal
        self.entries = entries.sorted { $0.recordedAt < $1.recordedAt }
        self.evaluatedAt = evaluatedAt
        self.calendar = calendar
    }

    public var total: Volume {
        entries.reduce(Volume.zero) { $0 + $1.volume }
    }

    public var remaining: Volume {
        goal.target.subtracting(total)
    }

    public var fraction: Double {
        guard goal.target.milliliters > 0 else { return 0 }
        return min(Double(total.milliliters) / Double(goal.target.milliliters), 1.0)
    }

    public var isToday: Bool {
        calendar.isDate(day, inSameDayAs: evaluatedAt)
    }

    public var expectedFraction: Double {
        guard isToday else { return 1 }

        let components = calendar.dateComponents([.hour, .minute], from: evaluatedAt)
        let hour = Double(components.hour ?? 0) + Double(components.minute ?? 0) / 60.0
        let start = Double(DailyProgress.activeDayStartHour)
        let end = Double(DailyProgress.activeDayEndHour)
        guard hour > start else { return 0 }
        guard hour < end else { return 1 }
        return (hour - start) / (end - start)
    }

    public var expectedVolume: Volume {
        goal.target.scaled(by: expectedFraction)
    }

    public var deficit: Volume {
        expectedVolume.subtracting(total)
    }

    public var status: HydrationStatus {
        let threshold = goal.target.scaled(by: DailyProgress.excessiveMultiplier)
        if total >= threshold { return .excessive }
        if total >= goal.target { return .reached }
        return total >= expectedVolume ? .onTrack : .behind
    }

    public var canAddMore: Bool {
        total < Volume.dailySafetyLimit
    }

    public var lastEntry: DrinkEntry? {
        entries.last
    }
}
