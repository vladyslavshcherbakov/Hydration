import HydrationDomain
import HydrationPairedDevice
import HydrationTestSupport
import XCTest
@testable import Hydration

@MainActor
final class SyncingWithTheWatchTests: XCTestCase {
    private var environment: PersistenceEnvironment!

    override func setUp() {
        super.setUp()
        environment = PersistenceEnvironment()
    }

    override func tearDown() {
        environment = nil
        super.tearDown()
    }

    // MARK: - Tests

    func test_todayScreen_whenWaterIsLogged_sendsItToTheWatch() async throws {
        await environment.dayScreen().quickAdd(milliliters: 250)

        XCTAssertEqual(environment.pairedDevice.sentDrinks.count, 1)
        XCTAssertEqual(environment.pairedDevice.sentDrinks.first?.amountML, 250)
    }

    func test_todayScreen_whenTheWatchLogsADrink_showsIt() async throws {
        try await environment.receiveFromPairedDevice(drinkFromTheWatch(450))

        let screen = environment.dayScreen()
        await screen.load()

        XCTAssertEqual(try screen.content.totalText, "0.45 L")
        XCTAssertEqual(try screen.content.entries.first?.amountText, "450 ml")
    }

    func test_todayScreen_whenTheWatchUndoesADrink_removesIt() async throws {
        let id = UUID()
        try await environment.receiveFromPairedDevice(drinkFromTheWatch(450, id: id))

        try await environment.receiveFromPairedDevice(
            PairedDeviceMessage(content: .drinkRemoved(DrinkRemovalMessage(id: id)))
        )

        let screen = environment.dayScreen()
        await screen.load()
        XCTAssertEqual(try screen.content.totalText, "0 L")
    }

    func test_todayScreen_whenTheSameDrinkArrivesTwice_countsItOnce() async throws {
        let drink = drinkFromTheWatch(500)

        try await environment.receiveFromPairedDevice(drink)
        try await environment.receiveFromPairedDevice(drink)

        let screen = environment.dayScreen()
        await screen.load()

        XCTAssertEqual(try screen.content.totalText, "0.5 L")
        XCTAssertEqual(try screen.content.entries.count, 1)
    }

    func test_todayScreen_whenTheOtherDeviceSendsSomethingUnreadable_ignoresIt() async throws {
        await environment.receiveFromPairedDevice(encoded: Data("not a message at all".utf8))

        let screen = environment.dayScreen()
        await screen.load()
        XCTAssertEqual(try screen.content.totalText, "0 L")
    }

    func test_todayScreen_whenTheOtherDeviceSendsAnImpossibleAmount_ignoresIt() async throws {
        for amount in [0, -250, 999_999] {
            try await environment.receiveFromPairedDevice(drinkFromTheWatch(amount))
        }

        let screen = environment.dayScreen()
        await screen.load()
        XCTAssertEqual(try screen.content.totalText, "0 L")
    }

    func test_todayScreen_whenADrinkComesFromANewerAppVersion_ignoresIt() async throws {
        try await environment.receiveFromPairedDevice(
            drinkFromTheWatch(250, version: PairedDeviceMessage.currentVersion + 1)
        )

        let screen = environment.dayScreen()
        await screen.load()
        XCTAssertEqual(try screen.content.totalText, "0 L")
    }

    func test_pairedDevice_whenTheAppBecomesActive_receivesDrinksTheWidgetLogged() async throws {
        try await environment.log(400, at: environment.date(hour: 9))

        await environment.todaySnapshotSender.sendToPairedDevice()

        XCTAssertEqual(environment.pairedDevice.sentSnapshots.count, 1)
        XCTAssertEqual(environment.pairedDevice.sentSnapshots.first?.drinks.count, 1)
        XCTAssertEqual(environment.pairedDevice.sentSnapshots.first?.drinks.first?.amountML, 400)
    }

    func test_pairedDevice_whenTheAppBecomesActive_receivesNothingFromEarlierDays() async throws {
        try await environment.log(400, at: environment.date(hour: 9, dayOffset: -1))

        await environment.todaySnapshotSender.sendToPairedDevice()

        XCTAssertEqual(environment.pairedDevice.sentSnapshots.count, 1)
        XCTAssertTrue(environment.pairedDevice.sentSnapshots.first?.drinks.isEmpty == true)
    }

    func test_pairedDevice_whenADrinkIsDeleted_receivesAPictureWithoutIt() async throws {
        let screen = environment.dayScreen()
        await screen.quickAdd(milliliters: 250)
        let logged = try XCTUnwrap(try screen.content.entries.first)

        await screen.remove(entryID: logged.id)
        await environment.todaySnapshotSender.sendToPairedDevice()

        XCTAssertTrue(environment.pairedDevice.sentSnapshots.last?.drinks.isEmpty == true)
    }

    func test_pairedDevice_whenItBecomesReachableLater_receivesTodaysDrinks() async throws {
        try await environment.log(400, at: environment.date(hour: 9))

        await environment.pairedDevice.becomeReachable()

        XCTAssertEqual(environment.pairedDevice.sentSnapshots.count, 1)
        XCTAssertEqual(environment.pairedDevice.sentSnapshots.first?.drinks.first?.amountML, 400)
    }

    // MARK: - Helpers

    private func drinkFromTheWatch(
        _ milliliters: Int,
        at hour: Int = 11,
        id: UUID = UUID(),
        version: Int = PairedDeviceMessage.currentVersion
    ) -> PairedDeviceMessage {
        PairedDeviceMessage(
            version: version,
            content: .drinkLogged(
                DrinkMessage(
                    id: id,
                    amountML: milliliters,
                    day: environment.today,
                    recordedAt: environment.date(hour: hour)
                )
            )
        )
    }
}
