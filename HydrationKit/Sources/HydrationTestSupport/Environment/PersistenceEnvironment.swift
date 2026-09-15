import Foundation
import HydrationDomain
import HydrationPersistence

public final class PersistenceEnvironment {
    public let coreDataStack: CoreDataStack
    public let localRepository: CoreDataDrinkRepository
    public let observedRepository: ObservedDrinkRepository
    public let dateProvider: MutableDateProvider
    public let calendar: Calendar
    public let locale: Locale
    public let goal: HydrationGoal
    public let silentLog: SilentLog

    public var today: Date {
        calendar.dayInterval(for: dateProvider.now()).start
    }

    // MARK: - Public

    public init(now: Date = DayFixture.moment(hour: 12), goal: HydrationGoal = .standard) {
        let log = SilentLog()
        let coreDataStack = CoreDataStack.inMemory()
        let coreDataRepository = CoreDataDrinkRepository(coreDataStack: coreDataStack, log: log)

        self.calendar = DayFixture.calendar
        self.locale = DayFixture.calendar.locale!
        self.goal = goal
        self.silentLog = log
        self.coreDataStack = coreDataStack
        self.dateProvider = MutableDateProvider(now: now)
        self.localRepository = coreDataRepository
        self.observedRepository = ObservedDrinkRepository(localStorage: coreDataRepository)
    }

    public func date(hour: Int, minute: Int = 0, dayOffset: Int = 0) -> Date {
        let startOfThatDay = calendar.date(byAdding: .day, value: dayOffset, to: today)!
        return calendar.date(byAdding: DateComponents(hour: hour, minute: minute), to: startOfThatDay)!
    }

    public func makeAddDrink(repository override: DrinkRepository? = nil) -> AddDrinkUseCase {
        AddDrinkUseCase(
            repository: override ?? observedRepository,
            dateProvider: dateProvider,
            calendar: calendar,
            goal: goal,
            identifierProvider: { UUID() }
        )
    }

    public func makeFetchDay(repository override: DrinkRepository? = nil) -> FetchDayProgressUseCase {
        FetchDayProgressUseCase(
            repository: override ?? observedRepository,
            dateProvider: dateProvider,
            calendar: calendar,
            goal: goal
        )
    }

    public func makeCurrentDay() -> CurrentDay {
        CurrentDay(dateProvider: dateProvider, calendar: calendar)
    }

    public func log(_ milliliters: Int, at date: Date) async throws {
        try await observedRepository.save(
            DrinkEntry(
                id: UUID(),
                volume: Volume(milliliters: milliliters)!,
                day: calendar.dayInterval(for: date).start,
                recordedAt: date
            )
        )
    }
}
