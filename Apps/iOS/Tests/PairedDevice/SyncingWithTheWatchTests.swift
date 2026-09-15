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

    private func changeFromTheWatch(_ milliliters: Int, at hour: Int = 11, id: UUID = UUID()) -> DrinkChangeMessage {
        DrinkChangeMessage(
            id: id.uuidString,
            amountML: milliliters,
            day: environment.today.timeIntervalSince1970,
            recordedAt: environment.date(hour: hour).timeIntervalSince1970,
            deleted: false,
            version: DrinkChangeMessage.currentVersion
        )
    }

    func test_todayScreen_whenWaterIsLogged_sendsItToTheWatch() async throws {
        await environment.dayScreen().quickAdd(milliliters: 250)

        XCTAssertEqual(environment.pairedDevice.sent.count, 1)
        XCTAssertEqual(environment.pairedDevice.sent.first?.amountML, 250)
        XCTAssertEqual(environment.pairedDevice.sent.first?.deleted, false)
    }

    func test_todayScreen_whenTheWatchLogsADrink_showsIt() async throws {
        await environment.receiveFromPairedDevice(changeFromTheWatch(450))

        let screen = environment.dayScreen()
        await screen.load()

        XCTAssertEqual(screen.state.totalText, "0.45 L")
        XCTAssertEqual(screen.state.entries.first?.amountText, "450 ml")
    }

    func test_todayScreen_whenTheWatchUndoesADrink_removesIt() async throws {
        let id = UUID()
        await environment.receiveFromPairedDevice(changeFromTheWatch(450, id: id))

        await environment.receiveFromPairedDevice(
            DrinkChangeMessage(id: id.uuidString, amountML: nil, day: nil, recordedAt: nil, deleted: true, version: 1)
        )

        let screen = environment.dayScreen()
        await screen.load()
        XCTAssertEqual(screen.state.totalText, "0 L")
    }

    func test_todayScreen_whenTheSameDrinkArrivesTwice_countsItOnce() async throws {
        let change = changeFromTheWatch(500)

        await environment.receiveFromPairedDevice(change)
        await environment.receiveFromPairedDevice(change)

        let screen = environment.dayScreen()
        await screen.load()

        XCTAssertEqual(screen.state.totalText, "0.5 L")
        XCTAssertEqual(screen.state.entries.count, 1)
    }

    func test_todayScreen_whenTheOtherDeviceSendsGarbage_ignoresIt() async throws {
        let broken = [
            DrinkChangeMessage(id: nil, amountML: 250, day: 1, recordedAt: 1, deleted: false, version: 1),
            DrinkChangeMessage(id: "not-a-uuid", amountML: 250, day: 1, recordedAt: 1, deleted: false, version: 1),
            DrinkChangeMessage(id: UUID().uuidString, amountML: nil, day: 1, recordedAt: 1, deleted: false, version: 1),
            DrinkChangeMessage(id: UUID().uuidString, amountML: 0, day: 1, recordedAt: 1, deleted: false, version: 1),
            DrinkChangeMessage(id: UUID().uuidString, amountML: -250, day: 1, recordedAt: 1, deleted: false, version: 1),
            DrinkChangeMessage(id: UUID().uuidString, amountML: 999_999, day: 1, recordedAt: 1, deleted: false, version: 1),
            DrinkChangeMessage(id: UUID().uuidString, amountML: 250, day: 1, recordedAt: nil, deleted: false, version: 1)
        ]

        for change in broken {
            await environment.receiveFromPairedDevice(change)
        }

        let screen = environment.dayScreen()
        await screen.load()
        XCTAssertEqual(screen.state.totalText, "0 L")
    }

    func test_todayScreen_whenADrinkComesFromANewerAppVersion_ignoresIt() async throws {
        await environment.receiveFromPairedDevice(
            DrinkChangeMessage(
                id: UUID().uuidString,
                amountML: 250,
                day: environment.today.timeIntervalSince1970,
                recordedAt: environment.date(hour: 11).timeIntervalSince1970,
                deleted: false,
                version: DrinkChangeMessage.currentVersion + 1
            )
        )

        let screen = environment.dayScreen()
        await screen.load()
        XCTAssertEqual(screen.state.totalText, "0 L")
    }

    func test_pairedDevice_whenTheAppBecomesActive_receivesDrinksTheWidgetLogged() async throws {
        try await environment.log(400, at: environment.date(hour: 9))

        await environment.todaysDrinksSender.sendToPairedDevice()

        XCTAssertEqual(environment.pairedDevice.sent.count, 1)
        XCTAssertEqual(environment.pairedDevice.sent.first?.amountML, 400)
    }

    func test_pairedDevice_whenTheAppBecomesActive_receivesNothingFromEarlierDays() async throws {
        try await environment.log(400, at: environment.date(hour: 9, dayOffset: -1))

        await environment.todaysDrinksSender.sendToPairedDevice()

        XCTAssertTrue(environment.pairedDevice.sent.isEmpty)
    }

    func test_pairedDevice_whenItBecomesReachableLater_receivesTodaysDrinks() async throws {
        try await environment.log(400, at: environment.date(hour: 9))

        await environment.pairedDevice.becomeReachable()

        XCTAssertEqual(environment.pairedDevice.sent.count, 1)
        XCTAssertEqual(environment.pairedDevice.sent.first?.amountML, 400)
    }
}
