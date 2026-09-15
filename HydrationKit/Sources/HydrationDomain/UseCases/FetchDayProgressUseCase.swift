import Foundation

public struct FetchDayProgressUseCase: Sendable {
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

    public func execute(day: Date) async throws -> DailyProgress {
        let now = dateProvider.now()
        let entries = try await repository.entries(of: day, in: calendar)
        return DailyProgress(
            day: day,
            goal: goal,
            entries: entries,
            evaluatedAt: now,
            calendar: calendar
        )
    }
}
