import HydrationDesignSystem
import HydrationDomain
import HydrationTestSupport
import XCTest
@testable import HydrationWatch

final class WhatTheWatchFaceSaysTests: XCTestCase {
    private var mapper: WatchTodayViewDataMapper!

    override func setUp() {
        super.setUp()
        mapper = WatchTodayViewDataMapper(calendar: DayFixture.calendar, locale: DayFixture.calendar.locale!)
    }

    override func tearDown() {
        mapper = nil
        super.tearDown()
    }

    // MARK: - Tests

    func test_watchFace_beforeTheDayArrives_saysItIsLoading() throws {
        let viewData = mapper.loading()

        guard case .loading(let loading) = viewData.state else { return XCTFail("expected loading") }
        XCTAssertEqual(viewData.title, "Water")
        XCTAssertEqual(loading.accessibilityLabel, "Loading")
    }

    func test_total_whenSevenHundredIsLogged_readsInLitresWithoutAUnit() throws {
        let content = try content(of: [DayFixture.drink(700, at: 9)])

        XCTAssertEqual(content.totalText, "0.7")
        XCTAssertEqual(content.goalText, "/ 2.5")
    }

    func test_status_whenTheDayIsLevelWithTheClock_saysOnTrack() throws {
        let content = try content(of: [DayFixture.drink(1250, at: 9)])

        XCTAssertEqual(content.statusText, "On track")
        XCTAssertEqual(content.accent, .neutral)
    }

    func test_status_whenTheDayIsAQuarterLitreShortOfTheClock_saysHowFarBehind() throws {
        let content = try content(of: [DayFixture.drink(1000, at: 9)])

        XCTAssertEqual(content.statusText, "250 ml behind")
        XCTAssertEqual(content.accent, .warning)
    }

    func test_status_whenTheWholeGoalIsLogged_saysItIsReached() throws {
        let content = try content(of: [DayFixture.drink(2500, at: 9)])

        XCTAssertEqual(content.statusText, "Goal reached")
        XCTAssertEqual(content.accent, .positive)
    }

    func test_status_whenHalfAgainTheGoalIsLogged_warns() throws {
        let content = try content(of: [DayFixture.drink(3750, at: 9)])

        XCTAssertEqual(content.statusText, "Above your goal")
        XCTAssertEqual(content.accent, .critical)
    }

    func test_amountButtons_whenTheDayIsEmpty_offerThreeSizes() throws {
        let content = try content(of: [])

        XCTAssertEqual(content.presets.map(\.title), ["+200", "+350", "+500"])
        XCTAssertEqual(content.presets.map(\.isEnabled), [true, true, true])
    }

    func test_amountButtons_whenOnlyTwoHundredStillFits_offerThatOneAlone() throws {
        let content = try content(of: [DayFixture.drink(5800, at: 9)])

        XCTAssertEqual(content.presets.map(\.isEnabled), [true, false, false])
    }

    func test_undoButton_whenTheLastDrinkWasHalfALitre_namesThatAmount() throws {
        let content = try content(of: [DayFixture.drink(250, at: 9), DayFixture.drink(500, at: 11)])

        XCTAssertEqual(content.undoTitle, "Undo 500 ml")
        XCTAssertTrue(content.isUndoEnabled)
    }

    func test_undoButton_whenTheDayIsEmpty_saysThereIsNothingToUndo() throws {
        let content = try content(of: [])

        XCTAssertEqual(content.undoTitle, "Nothing to undo")
        XCTAssertFalse(content.isUndoEnabled)
    }

    func test_watchFace_whenItIsRead_tellsVoiceOverTheTotalTheGoalAndTheStatus() throws {
        XCTAssertEqual(try content(of: [DayFixture.drink(1250, at: 9)]).accessibilityLabel, "1.25 of 2.5, On track")
    }

    func test_failure_whenTheSafetyLimitIsReached_saysLimit() throws {
        XCTAssertEqual(try failure(for: HydrationError.safetyLimitReached).message, "Limit")
    }

    func test_failure_whenThereIsNothingToUndo_saysSo() throws {
        XCTAssertEqual(try failure(for: HydrationError.nothingToRemove).message, "Nothing to undo")
    }

    func test_failure_whenTheDayCannotBeRead_offersARetry() throws {
        let failure = try failure(for: HydrationError.storageUnavailable)

        XCTAssertEqual(failure.message, "Retry")
        XCTAssertEqual(failure.accent, .critical)
    }

    // MARK: - Helpers

    private func content(of drinks: [DrinkEntry], at hour: Int = 15) throws -> WatchTodayViewData.Content {
        guard case .content(let content) = mapper.viewData(for: DayFixture.progress(drinks, at: hour)).state else {
            throw ScreenStateMismatch.notContent
        }
        return content
    }

    private func failure(for error: Error) throws -> WatchTodayViewData.Failure {
        guard case .failed(let failure) = mapper.viewData(for: error).state else {
            throw ScreenStateMismatch.notFailed
        }
        return failure
    }
}
