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

    func test_watchFace_whenThePhoneLogsADrink_showsTheNewTotal() async throws {
        await environment.receiveFromPairedDevice(
            DrinkChangeMessage(
                id: UUID().uuidString,
                amountML: 600,
                day: environment.today.timeIntervalSince1970,
                recordedAt: environment.date(hour: 11).timeIntervalSince1970,
                deleted: false,
                version: DrinkChangeMessage.currentVersion
            )
        )

        let screen = environment.todayScreen()
        await screen.load()

        XCTAssertEqual(screen.state.totalText, "0.6")
    }

    func test_watchFace_whenWaterIsLogged_sendsItToThePhone() async throws {
        let screen = environment.todayScreen()

        await screen.add(milliliters: 350)

        XCTAssertEqual(environment.pairedDevice.sent.count, 1)
        XCTAssertEqual(environment.pairedDevice.sent.first?.amountML, 350)
    }

    func test_undo_whenTapped_sendsARemovalToThePhone() async throws {
        let screen = environment.todayScreen()
        await screen.add(milliliters: 350)

        await screen.undoLast()

        XCTAssertEqual(environment.pairedDevice.sent.count, 2)
        XCTAssertEqual(environment.pairedDevice.sent.last?.deleted, true)
        XCTAssertEqual(environment.pairedDevice.sent.last?.id, environment.pairedDevice.sent.first?.id)
    }
}
