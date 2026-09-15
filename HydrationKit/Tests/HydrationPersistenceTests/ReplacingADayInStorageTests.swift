import CoreData
import HydrationDomain
import HydrationTestSupport
import XCTest
@testable import HydrationPersistence

final class ReplacingADayInStorageTests: XCTestCase {
    private var coreDataStack: CoreDataStack!
    private var repository: CoreDataDrinkRepository!

    override func setUp() {
        super.setUp()
        coreDataStack = CoreDataStack.inMemory()
        repository = CoreDataDrinkRepository(coreDataStack: coreDataStack, log: SilentLog())
    }

    override func tearDown() {
        coreDataStack = nil
        repository = nil
        super.tearDown()
    }

    // MARK: - Tests

    func test_day_whenReplacedByAPictureWithoutADrink_dropsThatDrink() async throws {
        let staying = DayFixture.drink(250, at: 9)
        try await repository.save(staying)
        try await repository.save(DayFixture.drink(500, at: 11))

        try await repository.replaceEntries(in: today, with: [staying])

        let entries = try await repository.entries(in: today)
        XCTAssertEqual(entries.map(\.volume.milliliters), [250])
    }

    func test_day_whenReplacedByAPictureWithANewDrink_storesIt() async throws {
        let arriving = DayFixture.drink(700, at: 14)

        try await repository.replaceEntries(in: today, with: [arriving])

        let entries = try await repository.entries(in: today)
        XCTAssertEqual(entries.map(\.id), [arriving.id])
    }

    func test_day_whenReplacedByAnEmptyPicture_isEmptied() async throws {
        try await repository.save(DayFixture.drink(250, at: 9))

        try await repository.replaceEntries(in: today, with: [])

        let entries = try await repository.entries(in: today)
        XCTAssertTrue(entries.isEmpty)
    }

    func test_earlierDays_whenTodayIsReplaced_areLeftAlone() async throws {
        try await repository.save(DayFixture.drink(900, at: 9, dayOffset: -1))

        try await repository.replaceEntries(in: today, with: [])

        let yesterday = DayFixture.calendar.dayInterval(
            for: DayFixture.calendar.date(byAdding: .day, value: -1, to: DayFixture.day)!
        )
        let entries = try await repository.entries(in: yesterday)
        XCTAssertEqual(entries.map(\.volume.milliliters), [900])
    }

    func test_day_whenThePictureRepeatsADrinkAlreadyStored_keepsOneCopy() async throws {
        let drink = DayFixture.drink(250, at: 9)
        try await repository.save(drink)

        try await repository.replaceEntries(in: today, with: [drink])

        let entries = try await repository.entries(in: today)
        XCTAssertEqual(entries.count, 1)
    }

    // MARK: - Helpers

    private var today: DateInterval {
        DayFixture.calendar.dayInterval(for: DayFixture.day)
    }
}
