import HydrationDomain
import HydrationRouting
import HydrationTestSupport
import XCTest
@testable import Hydration

@MainActor
final class KeepingDataSafeTests: XCTestCase {
    private var environment: PersistenceEnvironment!

    override func setUp() {
        super.setUp()
        environment = PersistenceEnvironment()
    }

    override func tearDown() {
        environment = nil
        super.tearDown()
    }

    func test_todayScreen_whenAnOddAmountIsLogged_showsItExactlyAfterReload() async throws {
        try await environment.log(333, at: environment.date(hour: 9))

        let screen = environment.dayScreen()
        await screen.load()

        XCTAssertEqual(screen.state.totalText, "0.33 L")
        XCTAssertEqual(screen.state.entries.first?.amountText, "333 ml")
        XCTAssertEqual(screen.state.entries.first?.timeText, "09:00")
    }

    func test_todayScreen_whenTheDataCannotBeRead_saysSo() async throws {
        let screen = environment.dayScreen(repository: FailingDrinkRepository())

        await screen.load()

        XCTAssertEqual(screen.state.statusText, "Could not load your hydration data")
        XCTAssertEqual(screen.state.accent, .critical)
    }
}
