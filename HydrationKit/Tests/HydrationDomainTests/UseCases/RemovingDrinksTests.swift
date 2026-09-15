import HydrationDomain
import HydrationTestSupport
import XCTest

final class RemovingDrinksTests: XCTestCase {
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

    func test_removeDrink_whenTheDayHasNoSuchDrink_refusesIt() async {
        await XCTAssertThrows(HydrationError.nothingToRemove) {
            _ = try await self.makeRemoveDrink().execute(id: UUID(), on: DayFixture.day)
        }
    }

    func test_removeDrink_whenTheDrinkBelongsToAnotherDay_refusesIt() async throws {
        let yesterday = DayFixture.drink(250, at: 9, dayOffset: -1)
        try await repository.save(yesterday)

        await XCTAssertThrows(HydrationError.nothingToRemove) {
            _ = try await self.makeRemoveDrink().execute(id: yesterday.id, on: DayFixture.day)
        }
    }

    func test_removeDrink_whenTheDrinkIsThere_dropsItFromTheDay() async throws {
        let morning = DayFixture.drink(250, at: 9)
        try await repository.save(morning)
        try await repository.save(DayFixture.drink(500, at: 11))

        let progress = try await makeRemoveDrink().execute(id: morning.id, on: DayFixture.day)

        XCTAssertEqual(progress.total.milliliters, 500)
        XCTAssertEqual(repository.stored.count, 1)
    }

    func test_removeLastDrink_whenTheDayIsEmpty_refusesIt() async {
        await XCTAssertThrows(HydrationError.nothingToRemove) {
            _ = try await self.makeRemoveLastDrink().execute(on: DayFixture.day)
        }
    }

    func test_removeLastDrink_whenDrinksExist_dropsTheLatestOne() async throws {
        try await repository.save(DayFixture.drink(250, at: 9))
        try await repository.save(DayFixture.drink(500, at: 18))

        let progress = try await makeRemoveLastDrink().execute(on: DayFixture.day)

        XCTAssertEqual(progress.total.milliliters, 250)
        XCTAssertEqual(repository.stored.first?.volume.milliliters, 250)
    }

    // MARK: - Helpers

    private func makeRemoveDrink() -> RemoveDrinkUseCase {
        RemoveDrinkUseCase(
            repository: repository,
            dateProvider: MutableDateProvider(now: DayFixture.moment(hour: 15)),
            calendar: DayFixture.calendar,
            goal: .standard
        )
    }

    private func makeRemoveLastDrink() -> RemoveLastDrinkUseCase {
        RemoveLastDrinkUseCase(
            repository: repository,
            dateProvider: MutableDateProvider(now: DayFixture.moment(hour: 15)),
            calendar: DayFixture.calendar,
            goal: .standard
        )
    }
}
