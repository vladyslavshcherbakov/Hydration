import Foundation

public struct FetchHistoryUseCase: Sendable {
    private let repository: DrinkRepository
    private let dateProvider: DateProvider
    private let calendar: Calendar
    private let goal: HydrationGoal

    public init(
        repository: DrinkRepository,
        dateProvider: DateProvider,
        calendar: Calendar,
        goal: HydrationGoal
    ) {
        self.repository = repository
        self.dateProvider = dateProvider
        self.calendar = calendar
        self.goal = goal
    }

    public func execute(days: Int) async throws -> [DailySummary] {
        guard days > 0 else { return [] }

        let today = calendar.dayInterval(for: dateProvider.now())
        guard let start = calendar.date(byAdding: .day, value: -(days - 1), to: today.start) else { return [] }

        let entries = try await repository.entries(in: DateInterval(start: start, end: today.end))
        let entriesByDay = Dictionary(grouping: entries, by: \.day)

        return (0..<days).compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today.start) else { return nil }
            let total = (entriesByDay[day] ?? []).reduce(Volume.zero) { $0 + $1.volume }
            return DailySummary(day: day, total: total, goal: goal)
        }
    }
}
