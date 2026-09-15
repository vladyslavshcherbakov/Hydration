import CoreData
import HydrationDomain
import HydrationTestSupport
import XCTest
@testable import HydrationPersistence

final class ReadingDrinksFromStorageTests: XCTestCase {
    private var coreDataStack: CoreDataStack!
    private var repository: CoreDataDrinkRepository!
    private var calendar: Calendar!
    private let reference = Date(timeIntervalSince1970: 1_700_000_000)

    override func setUp() {
        super.setUp()
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        self.calendar = calendar
        coreDataStack = CoreDataStack.inMemory()
        repository = CoreDataDrinkRepository(coreDataStack: coreDataStack, log: SilentLog())
    }

    override func tearDown() {
        coreDataStack = nil
        repository = nil
        calendar = nil
        super.tearDown()
    }

    private func insertRow(
        id: UUID?,
        amountML: Int64,
        day: Date?,
        recordedAt: Date?,
        schemaVersion: Int16 = DrinkEntryMapper.supportedSchemaVersion
    ) async throws {
        let context = coreDataStack.container.newBackgroundContext()
        try await context.perform {
            let managedEntry = CDDrinkEntry(context: context)
            managedEntry.id = id
            managedEntry.amountML = amountML
            managedEntry.day = day
            managedEntry.recordedAt = recordedAt
            managedEntry.schemaVersion = schemaVersion
            try context.save()
        }
    }

    private func readToday() async throws -> [DrinkEntry] {
        try await repository.entries(in: calendar.dayInterval(for: reference))
    }

    func test_day_whenARecordCannotBeRead_leavesItOut() async throws {
        let day = calendar.dayInterval(for: reference).start
        let morning = day.addingTimeInterval(9 * 3600)

        try await insertRow(id: UUID(), amountML: 300, day: day, recordedAt: morning)
        try await insertRow(id: nil, amountML: 300, day: day, recordedAt: morning)
        try await insertRow(id: UUID(), amountML: 300, day: day, recordedAt: nil)
        try await insertRow(id: UUID(), amountML: -50, day: day, recordedAt: morning)
        try await insertRow(id: UUID(), amountML: 999_999, day: day, recordedAt: morning)

        let entries = try await readToday()

        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries.first?.volume.milliliters, 300)
    }

    func test_day_whenARecordComesFromANewerVersion_leavesItOut() async throws {
        let day = calendar.dayInterval(for: reference).start
        let morning = day.addingTimeInterval(9 * 3600)

        try await insertRow(id: UUID(), amountML: 250, day: day, recordedAt: morning, schemaVersion: DrinkEntryMapper.supportedSchemaVersion + 1)

        let entries = try await readToday()

        XCTAssertTrue(entries.isEmpty)
    }
}
