import HydrationDesignSystem
import HydrationDomain
import HydrationRouting
import HydrationTestSupport
import XCTest
@testable import Hydration

@MainActor
final class ReviewingHistoryTests: XCTestCase {
    private var environment: AppGraphEnvironment!

    private var coordinator: AppCoordinator!

    override func setUp() {
        super.setUp()
        environment = AppGraphEnvironment()
        coordinator = AppCoordinator(selectedDay: environment.today)
    }

    override func tearDown() {
        environment = nil
        coordinator = nil
        super.tearDown()
    }

    // MARK: - Tests

    func test_historyScreen_whenOpened_showsTheLastTwoWeeks() async throws {
        try await seedThreeDays()

        let screen = environment.historyScreen(coordinator: coordinator)
        await screen.load()

        XCTAssertEqual(try screen.content.rows.count, 14)
        XCTAssertEqual(try screen.content.rows.first?.totalText, "2.6 L")
    }

    func test_historyRow_whenShown_carriesTheIdentifierTheUITestsLookFor() async throws {
        let screen = environment.historyScreen(coordinator: coordinator)

        await screen.load()

        XCTAssertEqual(try screen.content.rows.first?.identifier, "history.row.2023-11-14")
    }

    func test_historyScreen_whenAGoalWasMet_marksThatDay() async throws {
        try await seedThreeDays()

        let screen = environment.historyScreen(coordinator: coordinator)
        await screen.load()

        XCTAssertEqual(try screen.content.summaryText, "2 of 14 days on target")
        XCTAssertEqual(try screen.content.rows[0].badgeText, "Goal")
        XCTAssertNil(try screen.content.rows[1].badgeText)
        XCTAssertEqual(try screen.content.rows[1].accent, .warning)
    }

    func test_historyRow_whenTapped_isHighlighted() async throws {
        try await seedThreeDays()

        let screen = environment.historyScreen(coordinator: coordinator)
        await screen.load()
        let day = try XCTUnwrap(try screen.content.rows[1].id)

        screen.select(rowID: day)

        XCTAssertEqual(try screen.content.rows[1].isSelected, true)
        XCTAssertEqual(try screen.content.rows.filter(\.isSelected).count, 1)
    }

    func test_selectedDay_whenTheHistoryScreenIsReopened_isStillTicked() async throws {
        try await seedThreeDays()

        let firstVisit = environment.historyScreen(coordinator: coordinator)
        await firstVisit.load()
        firstVisit.select(rowID: try XCTUnwrap(try firstVisit.content.rows[2].id))

        let secondVisit = environment.historyScreen(coordinator: coordinator)
        await secondVisit.load()

        XCTAssertEqual(try secondVisit.content.rows[2].isSelected, true)
    }

    func test_historyRow_whenShown_isLabelledWithItsWeekdayAndDate() async throws {
        try await seedThreeDays()

        let screen = environment.historyScreen(coordinator: coordinator)
        await screen.load()

        XCTAssertEqual(try screen.content.rows[1].dayText, "Mon, 13 Nov")
        XCTAssertEqual(try screen.content.rows[2].dayText, "Sun, 12 Nov")
    }

    func test_historyScreen_whenNothingWasEverLogged_showsFourteenEmptyDays() async throws {
        let screen = environment.historyScreen(coordinator: coordinator)
        await screen.load()

        XCTAssertEqual(try screen.content.summaryText, "0 of 14 days on target")
        XCTAssertTrue(try screen.content.rows.allSatisfy { $0.totalText == "0 L" })
    }

    func test_historyRow_whenItIsTheCurrentDay_saysTodayInsteadOfTheDate() async throws {
        let screen = environment.historyScreen(coordinator: coordinator)

        await screen.load()

        XCTAssertEqual(try screen.content.rows[0].dayText, "Today")
    }

    // MARK: - Helpers

    private func seedThreeDays() async throws {
        try await environment.log(2600, at: environment.date(hour: 11))
        try await environment.log(1200, at: environment.date(hour: 11, dayOffset: -1))
        try await environment.log(2500, at: environment.date(hour: 11, dayOffset: -2))
    }
}
