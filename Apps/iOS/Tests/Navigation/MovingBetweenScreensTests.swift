import HydrationDomain
import HydrationRouting
import HydrationTestSupport
import XCTest
@testable import Hydration

@MainActor
final class MovingBetweenScreensTests: XCTestCase {
    private var environment: AppGraphEnvironment!
    private var coordinator: AppCoordinator!

    override func setUp() {
        super.setUp()
        environment = AppGraphEnvironment()
        coordinator = AppCoordinator(layout: .stack, selectedDay: environment.today)
    }

    override func tearDown() {
        environment = nil
        coordinator = nil
        super.tearDown()
    }

    // MARK: - Tests

    func test_historyButton_whenTheDayIsOpen_isLabelledHistory() async throws {
        let today = environment.dayScreen(coordinator: coordinator)

        await today.load()

        XCTAssertEqual(today.viewData.historyTitle, "History")
    }

    func test_historyButton_whenTapped_opensTheHistoryScreen() async throws {
        try await environment.log(2600, at: environment.date(hour: 11))
        let today = environment.dayScreen(coordinator: coordinator)

        today.openHistory()

        XCTAssertEqual(coordinator.path, [.history])
        let history = environment.historyScreen(coordinator: coordinator)
        await history.load()
        XCTAssertEqual(try history.content.rows.first?.totalText, "2.6 L")
    }

    func test_backButton_whenHistoryWasOpenedTwice_returnsToTodayInOneTap() async throws {
        try await environment.log(600, at: environment.date(hour: 11))
        let today = environment.dayScreen(coordinator: coordinator)
        today.openHistory()
        today.openHistory()

        coordinator.pop()

        XCTAssertTrue(coordinator.path.isEmpty)
        await today.load()
        XCTAssertEqual(try today.content.totalText, "0.6 L")
    }

    func test_selectedDay_whenTheUserReturnsToTheDayScreen_isStillTicked() async throws {
        try await environment.log(2600, at: environment.date(hour: 11))
        let history = environment.historyScreen(coordinator: coordinator)
        await history.load()
        coordinator.show(.history)
        let yesterday = try XCTUnwrap(try history.content.rows[1].id)
        history.select(rowID: yesterday)

        let reopened = environment.historyScreen(coordinator: coordinator)
        await reopened.load()

        XCTAssertTrue(coordinator.path.isEmpty)
        XCTAssertEqual(try reopened.content.rows[1].isSelected, true)
    }

    func test_historyScreen_whenNoDayWasEverTapped_ticksToday() async throws {
        try await environment.log(2600, at: environment.date(hour: 11))

        let history = environment.historyScreen(coordinator: coordinator)
        await history.load()

        XCTAssertEqual(try history.content.rows[0].isSelected, true)
    }

    func test_dayScreen_whenADayIsPickedInHistory_showsThatDay() async throws {
        try await environment.log(600, at: environment.date(hour: 9, dayOffset: -1))
        let history = environment.historyScreen(coordinator: coordinator)
        await history.load()

        history.select(rowID: try XCTUnwrap(try history.content.rows[1].id))

        let day = environment.dayScreen(day: coordinator.selectedDay)
        await day.load()
        XCTAssertEqual(try day.content.totalText, "0.6 L")
        XCTAssertEqual(day.viewData.title, "13 Nov")
    }
}
