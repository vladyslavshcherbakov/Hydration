import HydrationDomain
import HydrationRouting
import HydrationTestSupport
import XCTest
@testable import Hydration

@MainActor
final class MovingBetweenScreensTests: XCTestCase {
    private var environment: PersistenceEnvironment!
    private var coordinator: AppCoordinator!

    override func setUp() {
        super.setUp()
        environment = PersistenceEnvironment()
        coordinator = AppCoordinator(layout: .stack, selectedDay: environment.today)
    }

    override func tearDown() {
        environment = nil
        coordinator = nil
        super.tearDown()
    }

    func test_historyButton_whenTapped_opensTheHistoryScreen() async throws {
        try await environment.log(2600, at: environment.date(hour: 11))
        let today = environment.dayScreen(coordinator: coordinator)

        today.openHistory()

        XCTAssertEqual(coordinator.path, [.history])
        let history = environment.historyScreen(coordinator: coordinator)
        await history.load()
        XCTAssertEqual(history.state.rows.first?.totalText, "2.6 L")
    }

    func test_backButton_whenHistoryWasOpenedTwice_returnsToTodayInOneTap() async throws {
        try await environment.log(600, at: environment.date(hour: 11))
        let today = environment.dayScreen(coordinator: coordinator)
        today.openHistory()
        today.openHistory()

        coordinator.pop()

        XCTAssertTrue(coordinator.path.isEmpty)
        await today.load()
        XCTAssertEqual(today.state.totalText, "0.6 L")
    }

    func test_selectedDay_whenTheUserReturnsToTheDayScreen_isStillTicked() async throws {
        try await environment.log(2600, at: environment.date(hour: 11))
        let history = environment.historyScreen(coordinator: coordinator)
        await history.load()
        coordinator.show(.history)
        let yesterday = try XCTUnwrap(history.state.rows[1].id)
        history.select(rowID: yesterday)

        let reopened = environment.historyScreen(coordinator: coordinator)
        await reopened.load()

        XCTAssertTrue(coordinator.path.isEmpty)
        XCTAssertEqual(reopened.state.rows[1].isSelected, true)
    }

    func test_historyScreen_whenNoDayWasEverTapped_ticksToday() async throws {
        try await environment.log(2600, at: environment.date(hour: 11))

        let history = environment.historyScreen(coordinator: coordinator)
        await history.load()

        XCTAssertEqual(history.state.rows[0].isSelected, true)
    }

    func test_dayScreen_whenADayIsPickedInHistory_showsThatDay() async throws {
        try await environment.log(600, at: environment.date(hour: 9, dayOffset: -1))
        let history = environment.historyScreen(coordinator: coordinator)
        await history.load()

        history.select(rowID: try XCTUnwrap(history.state.rows[1].id))

        let day = environment.dayScreen(day: coordinator.selectedDay)
        await day.load()
        XCTAssertEqual(day.state.totalText, "0.6 L")
        XCTAssertEqual(day.state.title, "13 Nov")
    }
}
