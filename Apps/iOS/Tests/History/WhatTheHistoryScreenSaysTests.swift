import HydrationDesignSystem
import HydrationDomain
import HydrationTestSupport
import XCTest
@testable import Hydration

final class WhatTheHistoryScreenSaysTests: XCTestCase {
    private var mapper: HistoryViewDataMapper!

    override func setUp() {
        super.setUp()
        mapper = HistoryViewDataMapper(
            calendar: DayFixture.calendar,
            locale: DayFixture.calendar.locale!,
            today: DayFixture.day
        )
    }

    override func tearDown() {
        mapper = nil
        super.tearDown()
    }

    // MARK: - Tests

    func test_historyScreen_beforeTheDaysArrive_isWaitingUnderItsOwnTitle() {
        let viewData = mapper.loading()

        XCTAssertEqual(viewData.title, "History")
        XCTAssertEqual(viewData.state, .loading)
    }

    func test_summary_whenTwoOfThreeDaysReachedTheGoal_saysTwoOfThree() throws {
        let content = try content(of: [day(2600, ago: 0), day(1000, ago: 1), day(2500, ago: 2)])

        XCTAssertEqual(content.summaryText, "2 of 3 days on target")
    }

    func test_summary_whenNoDayReachedTheGoal_saysNoneOfThem() throws {
        XCTAssertEqual(try content(of: [day(1000, ago: 0)]).summaryText, "0 of 1 days on target")
    }

    func test_row_whenItIsTheCurrentDay_saysTodayInsteadOfTheDate() throws {
        XCTAssertEqual(try content(of: [day(1000, ago: 0)]).rows.map(\.dayText), ["Today"])
    }

    func test_row_whenItIsAnEarlierDay_namesTheWeekdayAndTheDate() throws {
        XCTAssertEqual(try content(of: [day(1000, ago: 1)]).rows.map(\.dayText), ["Mon, 13 Nov"])
    }

    func test_row_whenHalfTheGoalWasDrunk_showsTheTotalAndHalfTheBar() throws {
        let rows = try content(of: [day(1250, ago: 0)]).rows

        XCTAssertEqual(rows.map(\.totalText), ["1.25 L"])
        XCTAssertEqual(try XCTUnwrap(rows.first).fraction, 0.5, accuracy: 0.0001)
    }

    func test_row_whenTheGoalWasReached_carriesABadgeAndTheOtherDoesNot() throws {
        let rows = try content(of: [day(2500, ago: 0), day(1000, ago: 1)]).rows

        XCTAssertEqual(rows.map(\.badgeText), ["Goal", nil])
        XCTAssertEqual(rows.map(\.accent), [.positive, .warning])
    }

    func test_row_whenItIsTheSelectedDay_isTheOnlyOneTicked() throws {
        let yesterday = DayFixture.calendar.date(byAdding: .day, value: -1, to: DayFixture.day)!

        let content = try content(of: [day(1000, ago: 0), day(1000, ago: 1)], selected: yesterday)

        XCTAssertEqual(content.rows.map(\.isSelected), [false, true])
    }

    func test_row_whenItIsBuilt_carriesTheIdentifierTheUITestsLookFor() throws {
        XCTAssertEqual(try content(of: [day(1000, ago: 0)]).rows.map(\.identifier), ["history.row.2023-11-14"])
    }

    func test_historyScreen_whenTheDaysCannotBeRead_saysSoUnderItsOwnTitle() {
        let viewData = mapper.viewData(for: HydrationError.storageUnavailable)

        XCTAssertEqual(viewData.title, "History")
        XCTAssertEqual(viewData.state, .failed("Could not load history"))
    }

    // MARK: - Helpers

    private func day(_ milliliters: Int, ago dayOffset: Int) -> DailySummary {
        DailySummary(
            day: DayFixture.calendar.date(byAdding: .day, value: -dayOffset, to: DayFixture.day)!,
            total: Volume(milliliters: milliliters)!,
            goal: .standard
        )
    }

    private func content(of days: [DailySummary], selected: Date = DayFixture.day) throws -> HistoryViewData.Content {
        guard case .content(let content) = mapper.viewData(for: days, selected: selected).state else {
            throw ScreenStateMismatch.notContent
        }
        return content
    }
}
