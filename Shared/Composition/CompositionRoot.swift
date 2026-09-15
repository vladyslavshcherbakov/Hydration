import Foundation
import HydrationDomain

public struct CompositionRoot {
    public let repository: DrinkRepository
    public let dateProvider: DateProvider
    public let calendar: Calendar
    public let goal: HydrationGoal
    public let log: HydrationLog
    public let changes: DrinkChanges

    public var locale: Locale {
        calendar.locale ?? .current
    }

    private let identifierProvider: @Sendable () -> UUID

    public init(
        repository: DrinkRepository,
        changes: DrinkChanges,
        log: HydrationLog,
        dateProvider: DateProvider,
        calendar: Calendar = .current,
        goal: HydrationGoal = .standard,
        identifierProvider: @escaping @Sendable () -> UUID = { UUID() }
    ) {
        self.repository = repository
        self.changes = changes
        self.log = log
        self.dateProvider = dateProvider
        self.calendar = calendar
        self.goal = goal
        self.identifierProvider = identifierProvider
    }

    public func makeAddDrink() -> AddDrinkUseCase {
        AddDrinkUseCase(
            repository: repository,
            dateProvider: dateProvider,
            calendar: calendar,
            goal: goal,
            identifierProvider: identifierProvider
        )
    }

    public func makeCurrentDay() -> CurrentDay {
        CurrentDay(dateProvider: dateProvider, calendar: calendar)
    }

    public func makeFetchDay() -> FetchDayProgressUseCase {
        FetchDayProgressUseCase(repository: repository, dateProvider: dateProvider, calendar: calendar, goal: goal)
    }

    public func makeRemoveDrink() -> RemoveDrinkUseCase {
        RemoveDrinkUseCase(repository: repository, dateProvider: dateProvider, calendar: calendar, goal: goal)
    }

    public func makeRemoveLastDrink() -> RemoveLastDrinkUseCase {
        RemoveLastDrinkUseCase(repository: repository, dateProvider: dateProvider, calendar: calendar, goal: goal)
    }

    public func makeFetchHistory() -> FetchHistoryUseCase {
        FetchHistoryUseCase(repository: repository, dateProvider: dateProvider, calendar: calendar, goal: goal)
    }
}
