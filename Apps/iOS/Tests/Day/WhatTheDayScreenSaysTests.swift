import HydrationDesignSystem
import HydrationDomain
import HydrationTestSupport
import XCTest
@testable import Hydration

final class WhatTheDayScreenSaysTests: XCTestCase {
    private var mapper: DayViewDataMapper!

    override func setUp() {
        super.setUp()
        mapper = DayViewDataMapper(calendar: DayFixture.calendar, locale: DayFixture.calendar.locale!)
    }

    override func tearDown() {
        mapper = nil
        super.tearDown()
    }

    // MARK: - Tests

    func test_dayScreen_beforeTheDayArrives_saysItIsLoading() throws {
        let viewData = mapper.loading()

        guard case .loading(let loading) = viewData.state else { return XCTFail("expected loading") }
        XCTAssertEqual(viewData.title, "Today")
        XCTAssertEqual(loading.message, "Loading your day…")
        XCTAssertEqual(loading.accessibilityLabel, "Loading hydration progress")
    }

    func test_dayScreen_whenItShowsToday_isTitledToday() {
        XCTAssertEqual(mapper.viewData(for: DayFixture.progress([], at: 15)).title, "Today")
    }

    func test_dayScreen_whenItShowsAnEarlierDay_isTitledWithThatDate() {
        XCTAssertEqual(mapper.viewData(for: DayFixture.progress([], at: 15, dayOffset: -1)).title, "13 Nov")
    }

    func test_total_whenHalfTheGoalIsLogged_readsInLitresAgainstTheGoal() throws {
        let content = try content(of: [DayFixture.drink(1250, at: 9)])

        XCTAssertEqual(content.totalText, "1.25 L")
        XCTAssertEqual(content.goalText, "of 2.5 L")
        XCTAssertEqual(content.fraction, 0.5, accuracy: 0.0001)
    }

    func test_status_whenTheDayIsLevelWithTheClock_saysWhatIsLeft() throws {
        let content = try content(of: [DayFixture.drink(1250, at: 9)])

        XCTAssertEqual(content.statusText, "On track, 1250 ml to go")
        XCTAssertEqual(content.accent, .neutral)
    }

    func test_status_whenTheDayIsAQuarterLitreShortOfTheClock_saysHowFarBehind() throws {
        let content = try content(of: [DayFixture.drink(1000, at: 9)])

        XCTAssertEqual(content.statusText, "250 ml behind schedule")
        XCTAssertEqual(content.accent, .warning)
    }

    func test_status_whenTheWholeGoalIsLogged_saysItIsReached() throws {
        let content = try content(of: [DayFixture.drink(2500, at: 9)])

        XCTAssertEqual(content.statusText, "Daily goal reached")
        XCTAssertEqual(content.accent, .positive)
    }

    func test_status_whenHalfAgainTheGoalIsLogged_asksTheUserToSlowDown() throws {
        let content = try content(of: [DayFixture.drink(3750, at: 9)])

        XCTAssertEqual(content.statusText, "Well above your goal, consider slowing down")
        XCTAssertEqual(content.accent, .critical)
    }

    func test_quickAddButton_whenTheDayHasRoom_namesTheAmountItAdds() throws {
        let content = try content(of: [DayFixture.drink(250, at: 9)])

        XCTAssertEqual(content.quickAddTitle, "Add 250 ml")
        XCTAssertTrue(content.isQuickAddEnabled)
    }

    func test_quickAddButton_whenTheDayHoldsTheSafetyLimit_isDisabled() throws {
        XCTAssertFalse(try content(of: [DayFixture.drink(6000, at: 9)]).isQuickAddEnabled)
    }

    func test_drinks_whenTheDayHasSeveral_areListedNewestFirstWithTheirTime() throws {
        let content = try content(of: [DayFixture.drink(200, at: 9), DayFixture.drink(500, at: 14)])

        XCTAssertEqual(content.entries.map(\.amountText), ["500 ml", "200 ml"])
        XCTAssertEqual(content.entries.map(\.timeText), ["14:00", "09:00"])
    }

    func test_drink_whenItWasRecordedAfterMidnight_saysWhichDayItWasRecordedOn() throws {
        let afterMidnight = DrinkEntry(
            id: UUID(),
            volume: Volume(milliliters: 300)!,
            day: DayFixture.day,
            recordedAt: DayFixture.moment(hour: 1, dayOffset: 1)
        )

        XCTAssertEqual(try content(of: [afterMidnight]).entries.map(\.timeText), ["15 Nov, 01:00"])
    }

    func test_footnote_whenNothingIsLogged_saysSo() throws {
        XCTAssertEqual(try content(of: []).footnote, "No drinks logged yet")
    }

    func test_footnote_whenTwoDrinksAreLogged_countsThem() throws {
        let content = try content(of: [DayFixture.drink(200, at: 9), DayFixture.drink(500, at: 14)])

        XCTAssertEqual(content.footnote, "2 drinks logged")
    }

    func test_dayScreen_whenItIsRead_tellsVoiceOverTheTotalTheGoalAndTheStatus() throws {
        let content = try content(of: [DayFixture.drink(1250, at: 9)])

        XCTAssertEqual(content.accessibilityLabel, "1.25 liters of 2.5 liters, On track, 1250 ml to go")
    }

    func test_failure_whenTheSafetyLimitIsReached_namesTheLimit() throws {
        let failure = try failure(for: HydrationError.safetyLimitReached)

        XCTAssertEqual(failure.message, "You have reached the daily safety limit")
        XCTAssertEqual(failure.retryTitle, "Try again")
        XCTAssertEqual(failure.accent, .critical)
        XCTAssertEqual(failure.accessibilityLabel, failure.message)
    }

    func test_failure_whenTheAmountIsNotValid_saysSo() throws {
        XCTAssertEqual(try failure(for: HydrationError.invalidVolume).message, "That amount is not valid")
    }

    func test_failure_whenTheDayCannotBeRead_saysTheDataIsUnavailable() throws {
        XCTAssertEqual(try failure(for: HydrationError.storageUnavailable).message, "Could not load your hydration data")
    }

    func test_notice_whenAnActionIsRefused_saysTheSameSentenceTheFailureScreenWould() {
        XCTAssertEqual(mapper.notice(for: HydrationError.safetyLimitReached), "You have reached the daily safety limit")
        XCTAssertEqual(mapper.notice(for: HydrationError.invalidVolume), "That amount is not valid")
    }

    // MARK: - Helpers

    private func content(of drinks: [DrinkEntry], at hour: Int = 15) throws -> DayViewData.Content {
        guard case .content(let content) = mapper.viewData(for: DayFixture.progress(drinks, at: hour)).state else {
            throw ScreenStateMismatch.notContent
        }
        return content
    }

    private func failure(for error: Error) throws -> DayViewData.Failure {
        guard case .failed(let failure) = mapper.viewData(for: error).state else {
            throw ScreenStateMismatch.notFailed
        }
        return failure
    }
}
