import HydrationDomain
import HydrationPairedDevice
import HydrationTestSupport
import XCTest
@testable import HydrationWatch

@MainActor
final class SyncingWithThePhoneTests: XCTestCase {
    private var environment: PersistenceEnvironment!

    override func setUp() {
        super.setUp()
        environment = PersistenceEnvironment()
    }

    override func tearDown() {
        environment = nil
        super.tearDown()
    }

    private func drinkFromThePhone(_ milliliters: Int, at hour: Int = 11, id: UUID = UUID()) -> DrinkMessage {
        DrinkMessage(
            id: id,
            amountML: milliliters,
            day: environment.today,
            recordedAt: environment.date(hour: hour)
        )
    }

    private func pictureOfToday(
        _ drinks: [DrinkMessage],
        version: Int = PairedDeviceMessage.currentVersion
    ) -> PairedDeviceMessage {
        PairedDeviceMessage(
            version: version,
            content: .daySnapshot(DayOfDrinksMessage(day: environment.today, drinks: drinks))
        )
    }

    func test_watchFace_whenThePhoneLogsADrink_showsTheNewTotal() async throws {
        try await environment.receiveFromPairedDevice(
            PairedDeviceMessage(content: .drinkLogged(drinkFromThePhone(600)))
        )

        let screen = environment.todayScreen()
        await screen.load()

        XCTAssertEqual(screen.state.totalText, "0.6")
    }

    func test_watchFace_whenWaterIsLogged_sendsItToThePhone() async throws {
        let screen = environment.todayScreen()

        await screen.add(milliliters: 350)

        XCTAssertEqual(environment.pairedDevice.sentDrinks.count, 1)
        XCTAssertEqual(environment.pairedDevice.sentDrinks.first?.amountML, 350)
    }

    func test_undo_whenTapped_sendsARemovalToThePhone() async throws {
        let screen = environment.todayScreen()
        await screen.add(milliliters: 350)

        await screen.undoLast()

        XCTAssertEqual(environment.pairedDevice.sentRemovals.count, 1)
        XCTAssertEqual(environment.pairedDevice.sentRemovals.first?.id, environment.pairedDevice.sentDrinks.first?.id)
    }

    func test_watchFace_whenThePhonesPictureOfTodayArrives_dropsDrinksItNoLongerHolds() async throws {
        let screen = environment.todayScreen()
        await screen.add(milliliters: 350)

        try await environment.receiveFromPairedDevice(pictureOfToday([]))

        await screen.load()
        XCTAssertEqual(screen.state.totalText, "0")
    }

    func test_watchFace_whenThePhonesPictureOfTodayArrives_showsTheDrinksItHolds() async throws {
        try await environment.receiveFromPairedDevice(pictureOfToday([drinkFromThePhone(500, at: 10)]))

        let screen = environment.todayScreen()
        await screen.load()

        XCTAssertEqual(screen.state.totalText, "0.5")
    }

    func test_watchFace_whenAPictureFromANewerAppVersionArrives_keepsWhatItHas() async throws {
        let screen = environment.todayScreen()
        await screen.add(milliliters: 350)

        try await environment.receiveFromPairedDevice(
            pictureOfToday([], version: PairedDeviceMessage.currentVersion + 1)
        )

        await screen.load()
        XCTAssertEqual(screen.state.totalText, "0.35")
    }
}
