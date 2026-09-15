import Foundation
import HydrationDomain
import HydrationPersistence
import HydrationPairedDevice

public final class PersistenceEnvironment {
    public static let referenceNow = Date(timeIntervalSince1970: 1_699_963_200)

    public let coreDataStack: CoreDataStack
    public let localRepository: CoreDataDrinkRepository
    public let observedRepository: ObservedDrinkRepository
    public let repository: DrinkRepository
    public let pairedDevice: RecordingPairedDeviceChannel
    public let incomingChanges: IncomingDrinkChanges
    public let todaysDrinksSender: TodaysDrinksSender
    public let dateProvider: MutableDateProvider
    public let calendar: Calendar
    public let locale: Locale
    public let goal: HydrationGoal

    public var today: Date {
        calendar.dayInterval(for: dateProvider.now()).start
    }
    public let recordedLog: RecordingLog

    public init(now: Date = PersistenceEnvironment.referenceNow, goal: HydrationGoal = .standard) {
        let locale = Locale(identifier: "en_US_POSIX")
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        calendar.locale = locale

        let log = RecordingLog()
        let coreDataStack = CoreDataStack.inMemory()
        let coreDataRepository = CoreDataDrinkRepository(coreDataStack: coreDataStack, log: log)
        let observedRepository = ObservedDrinkRepository(localStorage: coreDataRepository)
        let pairedDevice = RecordingPairedDeviceChannel()

        self.calendar = calendar
        self.locale = locale
        self.goal = goal
        self.recordedLog = log
        self.coreDataStack = coreDataStack
        self.dateProvider = MutableDateProvider(now: now)
        self.localRepository = coreDataRepository
        self.observedRepository = observedRepository
        self.pairedDevice = pairedDevice
        self.repository = MirroringDrinkRepository(localStorage: observedRepository, pairedDevice: pairedDevice)
        self.incomingChanges = IncomingDrinkChanges(localStorage: observedRepository, pairedDevice: pairedDevice, log: log)
        self.todaysDrinksSender = TodaysDrinksSender(
            repository: observedRepository,
            pairedDevice: pairedDevice,
            currentDay: CurrentDay(dateProvider: self.dateProvider, calendar: calendar),
            calendar: calendar,
            log: log
        )
        let todaysDrinksSender = self.todaysDrinksSender
        pairedDevice.whenPairedDeviceBecomesReachable {
            await todaysDrinksSender.sendToPairedDevice()
        }
    }

    public func date(hour: Int, minute: Int = 0, dayOffset: Int = 0) -> Date {
        let dayStart = calendar.dayInterval(for: dateProvider.now()).start
        let startOfThatDay = calendar.date(byAdding: .day, value: dayOffset, to: dayStart)!
        return calendar.date(byAdding: DateComponents(hour: hour, minute: minute), to: startOfThatDay)!
    }

    public func makeAddDrink(repository override: DrinkRepository? = nil) -> AddDrinkUseCase {
        AddDrinkUseCase(
            repository: override ?? repository,
            dateProvider: dateProvider,
            calendar: calendar,
            goal: goal,
            identifierProvider: { UUID() }
        )
    }

    public func makeRemoveLast(repository override: DrinkRepository? = nil) -> RemoveLastDrinkUseCase {
        RemoveLastDrinkUseCase(repository: override ?? repository, dateProvider: dateProvider, calendar: calendar, goal: goal)
    }

    public func makeRemoveDrink(repository override: DrinkRepository? = nil) -> RemoveDrinkUseCase {
        RemoveDrinkUseCase(repository: override ?? repository, dateProvider: dateProvider, calendar: calendar, goal: goal)
    }

    public func makeFetchDay(repository override: DrinkRepository? = nil) -> FetchDayProgressUseCase {
        FetchDayProgressUseCase(repository: override ?? repository, dateProvider: dateProvider, calendar: calendar, goal: goal)
    }

    public func makeFetchHistory(repository override: DrinkRepository? = nil) -> FetchHistoryUseCase {
        FetchHistoryUseCase(repository: override ?? repository, dateProvider: dateProvider, calendar: calendar, goal: goal)
    }

    public func receiveFromPairedDevice(_ message: DrinkChangeMessage) async {
        incomingChanges.start()
        await pairedDevice.deliver(message)
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

    public func fillToDailyLimit(startingAt hour: Int = 12) async throws {
        dateProvider.set(date(hour: hour))
        let addDrink = makeAddDrink()
        for _ in 0..<6 {
            _ = try await addDrink.execute(milliliters: 1000, on: today)
            dateProvider.advance(by: 60)
        }
    }
}
