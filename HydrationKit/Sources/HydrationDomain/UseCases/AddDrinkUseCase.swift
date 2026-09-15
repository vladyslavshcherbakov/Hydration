import Foundation

public struct AddDrinkUseCase: Sendable {
    private let repository: DrinkRepository
    private let dateProvider: DateProvider
    private let calendar: Calendar
    private let goal: HydrationGoal
    private let identifierProvider: @Sendable () -> UUID

    public init(
        repository: DrinkRepository,
        dateProvider: DateProvider,
        calendar: Calendar,
        goal: HydrationGoal,
        identifierProvider: @escaping @Sendable () -> UUID
    ) {
        self.repository = repository
        self.dateProvider = dateProvider
        self.calendar = calendar
        self.goal = goal
        self.identifierProvider = identifierProvider
    }

    @discardableResult
    public func execute(milliliters: Int, on day: Date) async throws -> DailyProgress {
        guard let volume = Volume(milliliters: milliliters), volume > .zero else {
            throw HydrationError.invalidVolume
        }

        let now = dateProvider.now()
        let existing = try await repository.entries(of: day, in: calendar)
        let current = existing.reduce(Volume.zero) { $0 + $1.volume }

        guard current.milliliters + volume.milliliters <= Volume.dailySafetyLimit.milliliters else {
            throw HydrationError.safetyLimitReached
        }

        let entry = DrinkEntry(id: identifierProvider(), volume: volume, day: day, recordedAt: now)
        try await repository.save(entry)

        return DailyProgress(
            day: day,
            goal: goal,
            entries: existing + [entry],
            evaluatedAt: now,
            calendar: calendar
        )
    }
}
