import HydrationDomain
import HydrationTestSupport
import XCTest

final class AddDrinkUseCaseTests: XCTestCase {
    private var repository: InMemoryDrinkRepository!

    override func setUp() {
        super.setUp()
        repository = InMemoryDrinkRepository()
    }

    override func tearDown() {
        repository = nil
        super.tearDown()
    }

    // MARK: - Tests

    func test_execute_whenTheAmountIsZero_refusesIt() async {
        await XCTAssertThrows(HydrationError.invalidVolume) {
            _ = try await self.makeUseCase().execute(milliliters: 0, on: DayFixture.day)
        }
    }

    func test_execute_whenTheAmountIsNegative_refusesIt() async {
        await XCTAssertThrows(HydrationError.invalidVolume) {
            _ = try await self.makeUseCase().execute(milliliters: -250, on: DayFixture.day)
        }
    }

    func test_execute_whenTheAmountIsAboveTheSafetyLimit_refusesIt() async {
        await XCTAssertThrows(HydrationError.invalidVolume) {
            _ = try await self.makeUseCase().execute(milliliters: 6001, on: DayFixture.day)
        }
    }

    func test_execute_whenTheDayWouldPassTheSafetyLimit_refusesIt() async throws {
        try await repository.save(DayFixture.drink(5900, at: 9))

        await XCTAssertThrows(HydrationError.safetyLimitReached) {
            _ = try await self.makeUseCase().execute(milliliters: 250, on: DayFixture.day)
        }
    }

    func test_execute_whenTheDayWouldLandExactlyOnTheSafetyLimit_storesIt() async throws {
        try await repository.save(DayFixture.drink(5750, at: 9))

        let progress = try await makeUseCase().execute(milliliters: 250, on: DayFixture.day)

        XCTAssertEqual(progress.total, .dailySafetyLimit)
    }

    func test_execute_whenTheAmountIsValid_storesItAndReturnsTheNewDay() async throws {
        let progress = try await makeUseCase().execute(milliliters: 250, on: DayFixture.day)

        XCTAssertEqual(progress.total.milliliters, 250)
        XCTAssertEqual(repository.stored.count, 1)
        XCTAssertEqual(repository.stored.first?.volume.milliliters, 250)
    }

    func test_execute_whenTheDrinkIsStored_recordsTheMomentItHappened() async throws {
        _ = try await makeUseCase(now: DayFixture.moment(hour: 11)).execute(milliliters: 250, on: DayFixture.day)

        XCTAssertEqual(repository.stored.first?.recordedAt, DayFixture.moment(hour: 11))
        XCTAssertEqual(repository.stored.first?.day, DayFixture.day)
    }

    func test_execute_whenTheStoreFails_passesTheFailureOn() async {
        let useCase = AddDrinkUseCase(
            repository: FailingDrinkRepository(),
            dateProvider: MutableDateProvider(now: DayFixture.moment(hour: 11)),
            calendar: DayFixture.calendar,
            goal: .standard,
            identifierProvider: { UUID() }
        )

        await XCTAssertThrows(HydrationError.storageUnavailable) {
            _ = try await useCase.execute(milliliters: 250, on: DayFixture.day)
        }
    }

    // MARK: - Helpers

    private func makeUseCase(now: Date = DayFixture.moment(hour: 15)) -> AddDrinkUseCase {
        AddDrinkUseCase(
            repository: repository,
            dateProvider: MutableDateProvider(now: now),
            calendar: DayFixture.calendar,
            goal: .standard,
            identifierProvider: { UUID() }
        )
    }
}
