import HydrationDesignSystem
import HydrationDomain
import HydrationRouting
import HydrationTestSupport
import XCTest
@testable import Hydration

@MainActor
final class KeepingDataSafeTests: XCTestCase {
    private var environment: AppGraphEnvironment!

    override func setUp() {
        super.setUp()
        environment = AppGraphEnvironment()
    }

    override func tearDown() {
        environment = nil
        super.tearDown()
    }

    // MARK: - Tests

    func test_todayScreen_whenAnOddAmountIsLogged_showsItExactlyAfterReload() async throws {
        try await environment.log(333, at: environment.date(hour: 9))

        let screen = environment.dayScreen()
        await screen.load()

        XCTAssertEqual(try screen.content.totalText, "0.33 L")
        XCTAssertEqual(try screen.content.entries.first?.amountText, "333 ml")
        XCTAssertEqual(try screen.content.entries.first?.timeText, "09:00")
    }

    func test_todayScreen_whenTheDataCannotBeRead_saysSo() async throws {
        let broken = AppGraphEnvironment(storage: FailingDrinkRepository())
        let screen = broken.dayScreen()

        await screen.load()

        XCTAssertEqual(try screen.failure.message, "Could not load your hydration data")
        XCTAssertEqual(try screen.failure.accent, .critical)
    }

    func test_historyScreen_whenTheDataCannotBeRead_saysSoInsteadOfShowingEmptyDays() async throws {
        let broken = AppGraphEnvironment(storage: FailingDrinkRepository())
        let screen = broken.historyScreen(coordinator: AppCoordinator(selectedDay: broken.today))

        await screen.load()

        XCTAssertEqual(try screen.failure, "Could not load history")
    }
}
