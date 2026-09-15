import Foundation

public struct RemoveLastDrinkUseCase: Sendable {
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

    @discardableResult
    public func execute(on day: Date) async throws -> DailyProgress {
        let now = dateProvider.now()
        let entries = try await repository.entries(of: day, in: calendar)

        guard let last = entries.last else {
            throw HydrationError.nothingToRemove
        }

        try await repository.delete(id: last.id)

        return DailyProgress(
            day: day,
            goal: goal,
            entries: Array(entries.dropLast()),
            evaluatedAt: now,
            calendar: calendar
        )
    }
}
