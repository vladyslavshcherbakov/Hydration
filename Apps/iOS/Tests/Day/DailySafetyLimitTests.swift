import HydrationDesignSystem
import HydrationDomain
import HydrationRouting
import HydrationTestSupport
import XCTest
@testable import Hydration

@MainActor
final class DailySafetyLimitTests: XCTestCase {
    private var environment: PersistenceEnvironment!

    override func setUp() {
        super.setUp()
        environment = PersistenceEnvironment()
    }

    override func tearDown() {
        environment = nil
        super.tearDown()
    }

    func test_dailyTotal_whenTheSafetyLimitIsReached_stopsGrowing() async throws {
        try await environment.fillToDailyLimit()

        let screen = environment.dayScreen()
        await screen.load()
        XCTAssertEqual(try screen.content.totalText, "6 L")

        await screen.quickAdd()

        let reopened = environment.dayScreen()
        await reopened.load()
        XCTAssertEqual(try reopened.content.totalText, "6 L")
        XCTAssertEqual(try reopened.content.entries.count, 6)
    }

    func test_todayScreen_whenADrinkIsRefused_saysWhyAndKeepsTheDayOnScreen() async throws {
        try await environment.fillToDailyLimit()

        let screen = environment.dayScreen()
        await screen.load()

        await screen.quickAdd()

        XCTAssertEqual(screen.notice, "You have reached the daily safety limit")
        XCTAssertEqual(try screen.content.totalText, "6 L")
        XCTAssertEqual(try screen.content.entries.count, 6)
    }

    func test_todayScreen_whenTheUserDismissesTheRefusal_stopsSayingIt() async throws {
        try await environment.fillToDailyLimit()
        let screen = environment.dayScreen()
        await screen.load()
        await screen.quickAdd()

        screen.dismissNotice()

        XCTAssertNil(screen.notice)
    }

    func test_widgetLink_whenItWouldExceedTheLimit_isRefused() async throws {
        try await environment.fillToDailyLimit()

        let outcome = await environment.deepLinkOpener(coordinator: AppCoordinator(selectedDay: environment.today))
            .open(.addDrink(milliliters: Volume.quickAdd.milliliters))

        XCTAssertEqual(outcome, .rejected(.safetyLimitReached))

        let screen = environment.dayScreen()
        await screen.load()
        XCTAssertEqual(try screen.content.totalText, "6 L")
    }
}
