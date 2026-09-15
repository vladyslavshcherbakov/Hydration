import Foundation

public struct RemoveDrinkUseCase: Sendable {
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
    public func execute(id: UUID, on day: Date) async throws -> DailyProgress {
        let now = dateProvider.now()
        let entries = try await repository.entries(of: day, in: calendar)

        guard entries.contains(where: { $0.id == id }) else {
            throw HydrationError.nothingToRemove
        }

        try await repository.delete(id: id)

        return DailyProgress(
            day: day,
            goal: goal,
            entries: entries.filter { $0.id != id },
            evaluatedAt: now,
            calendar: calendar
        )
    }
}
