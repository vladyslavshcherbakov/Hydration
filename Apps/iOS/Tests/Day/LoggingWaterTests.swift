import HydrationDomain
import HydrationRouting
import HydrationTestSupport
import XCTest
@testable import Hydration

@MainActor
final class LoggingWaterTests: XCTestCase {
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

    func test_todayScreen_whenTheDayIsEmpty_saysNoDrinksLoggedYet() async throws {
        let screen = environment.dayScreen()
        await screen.load()

        XCTAssertEqual(try screen.content.totalText, "0 L")
        XCTAssertEqual(try screen.content.footnote, "No drinks logged yet")
        XCTAssertTrue(try screen.content.entries.isEmpty)
    }

    func test_quickAddButton_whenTheDayHasRoom_namesTheAmountItWillAdd() async throws {
        let screen = environment.dayScreen()

        await screen.load()

        XCTAssertEqual(try screen.content.quickAddTitle, "Add 250 ml")
        XCTAssertTrue(try screen.content.isQuickAddEnabled)
    }

    func test_quickAddButton_whenTheDayIsAtTheSafetyLimit_isDisabled() async throws {
        try await environment.log(6000, at: environment.date(hour: 9))
        let screen = environment.dayScreen()

        await screen.load()

        XCTAssertFalse(try screen.content.isQuickAddEnabled)
    }

    func test_dailyTotal_whenTwoDifferentSizesAreLogged_addsThemUp() async throws {
        try await environment.log(300, at: environment.date(hour: 9))
        try await environment.log(450, at: environment.date(hour: 11))

        let screen = environment.dayScreen()
        await screen.load()

        XCTAssertEqual(try screen.content.totalText, "0.75 L")
        XCTAssertEqual(try screen.content.entries.count, 2)
    }

    func test_quickAdd_whenTappedTwice_showsHalfALitre() async throws {
        let screen = environment.dayScreen()
        await screen.load()
        XCTAssertEqual(try screen.content.totalText, "0 L")

        await screen.quickAdd()
        await screen.quickAdd()

        XCTAssertEqual(try screen.content.totalText, "0.5 L")
    }

    func test_todayScreen_whenDrinksAreLogged_listsEachWithItsTime() async throws {
        try await environment.log(250, at: environment.date(hour: 9, minute: 15))
        try await environment.log(500, at: environment.date(hour: 11, minute: 40))

        let screen = environment.dayScreen()
        await screen.load()

        XCTAssertEqual(try screen.content.entries.map(\.amountText), ["500 ml", "250 ml"])
        XCTAssertEqual(try screen.content.entries.map(\.timeText), ["11:40", "09:15"])
        XCTAssertEqual(try screen.content.footnote, "2 drinks logged")
    }

    func test_dailyTotal_whenTheNextDayStarts_startsFromZero() async throws {
        await environment.dayScreen().quickAdd(milliliters: 750)

        environment.dateProvider.advance(by: 86_400)
        let nextDay = environment.dayScreen()
        await nextDay.load()

        XCTAssertEqual(try nextDay.content.totalText, "0 L")
        XCTAssertTrue(try nextDay.content.entries.isEmpty)
    }

    func test_dayEntry_whenRemoved_dropsOutOfTheTotal() async throws {
        try await environment.log(300, at: environment.date(hour: 9))
        try await environment.log(200, at: environment.date(hour: 10))
        let screen = environment.dayScreen()
        await screen.load()

        let morningDrink = try XCTUnwrap(try screen.content.entries.last)
        await screen.remove(entryID: morningDrink.id)

        XCTAssertEqual(try screen.content.totalText, "0.2 L")
        XCTAssertEqual(try screen.content.entries.count, 1)
    }
}
