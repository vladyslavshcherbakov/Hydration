import Foundation
import HydrationDomain
import HydrationTestSupport
import XCTest
@testable import HydrationPersistence

final class ObservedDrinkRepositoryTests: XCTestCase {
    private var repository: ObservedDrinkRepository!

    override func setUp() {
        super.setUp()
        repository = ObservedDrinkRepository(localStorage: InMemoryDrinkRepository())
    }

    override func tearDown() {
        repository = nil
        super.tearDown()
    }

    // MARK: - Tests

    func test_listeners_whenTwoAreWatching_areBothTold() async throws {
        let first = expectation(description: "the first listener hears it")
        let second = expectation(description: "the second listener hears it")
        let watching = Task { [repository] in
            await withTaskGroup(of: Void.self) { group in
                group.addTask { for await _ in repository!.whenDrinksChange() { first.fulfill(); return } }
                group.addTask { for await _ in repository!.whenDrinksChange() { second.fulfill(); return } }
            }
        }
        try await Task.sleep(nanoseconds: 50_000_000)

        try await repository.save(DayFixture.drink(250, at: 9))

        await fulfillment(of: [first, second], timeout: 1)
        watching.cancel()
    }

    func test_listener_whenADrinkIsStored_isToldWhichDayItLandedOn() async throws {
        let yesterday = DayFixture.calendar.date(byAdding: .day, value: -1, to: DayFixture.day)!

        let change = try await announcedChange {
            try await self.repository.save(DayFixture.drink(250, at: 9, dayOffset: -1))
        }

        XCTAssertEqual(change, .onDay(yesterday))
    }

    func test_listener_whenADayIsReplaced_isToldWhichDay() async throws {
        let change = try await announcedChange {
            try await self.repository.replaceEntries(
                in: DayFixture.calendar.dayInterval(for: DayFixture.day),
                with: []
            )
        }

        XCTAssertEqual(change, .onDay(DayFixture.day))
    }

    func test_listener_whenAnotherProcessWrote_isToldTheDayIsUnknown() async throws {
        let change = try await announcedChange { self.repository.noteWrittenElsewhere() }

        XCTAssertEqual(change, .onAnUnknownDay)
    }

    func test_listener_whenADrinkIsRemoved_isToldTheDayIsUnknown() async throws {
        let drink = DayFixture.drink(250, at: 9)
        try await repository.save(drink)

        let change = try await announcedChange { try await self.repository.delete(id: drink.id) }

        XCTAssertEqual(change, .onAnUnknownDay)
    }

    func test_reads_whenAsked_comeFromTheStorageBelow() async throws {
        try await repository.save(DayFixture.drink(250, at: 9))

        let entries = try await repository.entries(of: DayFixture.day, in: DayFixture.calendar)

        XCTAssertEqual(entries.map(\.volume.milliliters), [250])
    }

    // MARK: - Helpers

    private func announcedChange(_ write: @escaping () async throws -> Void) async throws -> DrinkChange? {
        let told = expectation(description: "the listener hears the change")
        let heard = Heard()
        let watching = Task { [repository] in
            for await change in repository!.whenDrinksChange() {
                heard.note(change)
                told.fulfill()
                return
            }
        }
        try await Task.sleep(nanoseconds: 50_000_000)

        try await write()

        await fulfillment(of: [told], timeout: 1)
        watching.cancel()
        return heard.change
    }
}

// MARK: - Heard

private final class Heard: @unchecked Sendable {
    private let lock = NSLock()
    private var heard: DrinkChange?

    var change: DrinkChange? {
        lock.lock()
        defer { lock.unlock() }
        return heard
    }

    func note(_ change: DrinkChange) {
        lock.lock()
        heard = change
        lock.unlock()
    }
}
