import Foundation
import HydrationDomain
import HydrationTestSupport
import XCTest
@testable import HydrationPairedDevice

final class IncomingDrinkChangesTests: XCTestCase {
    private var storage: InMemoryDrinkRepository!
    private var pairedDevice: RecordingPairedDeviceChannel!

    override func setUp() {
        super.setUp()
        storage = InMemoryDrinkRepository()
        pairedDevice = RecordingPairedDeviceChannel()
        IncomingDrinkChanges(
            localStorage: storage,
            pairedDevice: pairedDevice,
            calendar: DayFixture.calendar,
            log: SilentLog()
        ).start()
    }

    override func tearDown() {
        storage = nil
        pairedDevice = nil
        super.tearDown()
    }

    // MARK: - Tests

    func test_loggedDrink_whenItArrives_isStored() async throws {
        try await pairedDevice.deliver(PairedDeviceMessage(content: .drinkLogged(drink(450))))

        XCTAssertEqual(storage.stored.map(\.volume.milliliters), [450])
    }

    func test_loggedDrink_whenTheSameOneArrivesTwice_isStoredOnce() async throws {
        let arriving = drink(500)

        try await pairedDevice.deliver(PairedDeviceMessage(content: .drinkLogged(arriving)))
        try await pairedDevice.deliver(PairedDeviceMessage(content: .drinkLogged(arriving)))

        XCTAssertEqual(storage.stored.count, 1)
    }

    func test_loggedDrink_whenItsAmountIsImpossible_isDropped() async throws {
        try await pairedDevice.deliver(PairedDeviceMessage(content: .drinkLogged(drink(9000))))

        XCTAssertTrue(storage.stored.isEmpty)
    }

    func test_removal_whenItArrives_dropsTheDrink() async throws {
        let arriving = drink(450)
        try await pairedDevice.deliver(PairedDeviceMessage(content: .drinkLogged(arriving)))

        try await pairedDevice.deliver(
            PairedDeviceMessage(content: .drinkRemoved(DrinkRemovalMessage(id: arriving.id)))
        )

        XCTAssertTrue(storage.stored.isEmpty)
    }

    func test_removal_whenTheDrinkWasNeverStored_changesNothing() async throws {
        try await pairedDevice.deliver(PairedDeviceMessage(content: .drinkLogged(drink(450))))

        try await pairedDevice.deliver(
            PairedDeviceMessage(content: .drinkRemoved(DrinkRemovalMessage(id: UUID())))
        )

        XCTAssertEqual(storage.stored.count, 1)
    }

    func test_dayOfDrinks_whenItArrives_replacesThatDay() async throws {
        try await storage.save(DayFixture.drink(250, at: 9))

        try await pairedDevice.deliver(
            PairedDeviceMessage(content: .daySnapshot(DayOfDrinksMessage(day: DayFixture.day, drinks: [drink(700)])))
        )

        XCTAssertEqual(storage.stored.map(\.volume.milliliters), [700])
    }

    func test_dayOfDrinks_whenItIsEmpty_emptiesThatDay() async throws {
        try await storage.save(DayFixture.drink(250, at: 9))

        try await pairedDevice.deliver(
            PairedDeviceMessage(content: .daySnapshot(DayOfDrinksMessage(day: DayFixture.day, drinks: [])))
        )

        XCTAssertTrue(storage.stored.isEmpty)
    }

    func test_dayOfDrinks_whenItArrives_leavesOtherDaysAlone() async throws {
        try await storage.save(DayFixture.drink(250, at: 9, dayOffset: -1))

        try await pairedDevice.deliver(
            PairedDeviceMessage(content: .daySnapshot(DayOfDrinksMessage(day: DayFixture.day, drinks: [])))
        )

        XCTAssertEqual(storage.stored.map(\.volume.milliliters), [250])
    }

    func test_dayOfDrinks_whenOneDrinkInItIsImpossible_leavesTheDayAlone() async throws {
        try await storage.save(DayFixture.drink(250, at: 9))

        try await pairedDevice.deliver(
            PairedDeviceMessage(
                content: .daySnapshot(DayOfDrinksMessage(day: DayFixture.day, drinks: [drink(700), drink(9000)]))
            )
        )

        XCTAssertEqual(storage.stored.map(\.volume.milliliters), [250])
    }

    func test_message_whenTheBytesCannotBeRead_changesNothing() async throws {
        try await storage.save(DayFixture.drink(250, at: 9))

        await pairedDevice.deliver(Data("not a message".utf8))

        XCTAssertEqual(storage.stored.count, 1)
    }

    // MARK: - Helpers

    private func drink(_ milliliters: Int, at hour: Int = 11) -> DrinkMessage {
        DrinkMessage(
            id: UUID(),
            amountML: milliliters,
            day: DayFixture.day,
            recordedAt: DayFixture.moment(hour: hour)
        )
    }
}
