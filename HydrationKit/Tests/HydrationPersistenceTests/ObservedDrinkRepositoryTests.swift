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

    func test_listener_whenADrinkIsStored_isTold() async throws {
        try await assertAnnounces { try await self.repository.save(DayFixture.drink(250, at: 9)) }
    }

    func test_listener_whenADrinkIsRemoved_isTold() async throws {
        let drink = DayFixture.drink(250, at: 9)
        try await repository.save(drink)

        try await assertAnnounces { try await self.repository.delete(id: drink.id) }
    }

    func test_listener_whenADayIsReplaced_isTold() async throws {
        try await assertAnnounces {
            try await self.repository.replaceEntries(in: DayFixture.calendar.dayInterval(for: DayFixture.day), with: [])
        }
    }

    func test_listener_whenAnotherProcessWrote_isTold() async throws {
        try await assertAnnounces { self.repository.noteWrittenElsewhere() }
    }

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

    func test_reads_whenAsked_comeFromTheStorageBelow() async throws {
        try await repository.save(DayFixture.drink(250, at: 9))

        let entries = try await repository.entries(of: DayFixture.day, in: DayFixture.calendar)

        XCTAssertEqual(entries.map(\.volume.milliliters), [250])
    }

    // MARK: - Helpers

    private func assertAnnounces(_ write: @escaping () async throws -> Void) async throws {
        let told = expectation(description: "the listener hears the change")
        let watching = Task { [repository] in
            for await _ in repository!.whenDrinksChange() {
                told.fulfill()
                return
            }
        }
        try await Task.sleep(nanoseconds: 50_000_000)

        try await write()

        await fulfillment(of: [told], timeout: 1)
        watching.cancel()
    }
}
