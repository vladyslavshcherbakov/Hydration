import HydrationDesignSystem
import HydrationDomain
import HydrationTestSupport
import XCTest

#if canImport(WidgetKit)

final class WhatTheWidgetSaysTests: XCTestCase {
    private var mapper: WidgetTodayViewDataMapper!

    override func setUp() {
        super.setUp()
        mapper = WidgetTodayViewDataMapper(calendar: DayFixture.calendar, locale: DayFixture.calendar.locale!)
    }

    override func tearDown() {
        mapper = nil
        super.tearDown()
    }

    // MARK: - Tests

    func test_widget_inTheGalleryBeforeAnyDayIsRead_showsAFilledInFaceWithTheButtonOff() throws {
        let viewData = mapper.placeholder()

        guard case .content(let content) = viewData.state else { throw ScreenStateMismatch.notContent }
        XCTAssertEqual(viewData.title, "Water")
        XCTAssertEqual(content.totalText, "1.2 L")
        XCTAssertEqual(content.goalText, "of 2.5 L")
        XCTAssertFalse(content.isQuickAddEnabled)
    }

    func test_total_whenHalfTheGoalIsLogged_readsInLitresAgainstTheGoal() throws {
        let content = try content(of: [DayFixture.drink(1250, at: 9)])

        XCTAssertEqual(content.totalText, "1.25 L")
        XCTAssertEqual(content.goalText, "of 2.5 L")
        XCTAssertEqual(content.fraction, 0.5, accuracy: 0.0001)
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

    func test_status_whenHalfAgainTheGoalIsLogged_saysItIsAboveTheGoal() throws {
        let content = try content(of: [DayFixture.drink(3750, at: 9)])

        XCTAssertEqual(content.statusText, "Above goal")
        XCTAssertEqual(content.accent, .critical)
    }

    func test_quickAddButton_whenTheDayHasRoom_offersAQuarterLitre() throws {
        let content = try content(of: [DayFixture.drink(250, at: 9)])

        XCTAssertEqual(content.quickAddTitle, "+250")
        XCTAssertTrue(content.isQuickAddEnabled)
    }

    func test_quickAddButton_whenTheDayHoldsTheSafetyLimit_isDisabled() throws {
        XCTAssertFalse(try content(of: [DayFixture.drink(6000, at: 9)]).isQuickAddEnabled)
    }

    func test_footnote_whenTheDayIsRead_saysWhenItWasRead() throws {
        XCTAssertEqual(try content(of: [], at: 9).footnote, "Updated 09:00")
    }

    func test_widget_whenItIsRead_tellsVoiceOverTheTotalTheGoalAndTheStatus() throws {
        XCTAssertEqual(try content(of: [DayFixture.drink(1250, at: 9)]).accessibilityLabel, "1.25 of 2.5, On track")
    }

    func test_failure_whenTheDayCannotBeRead_sendsTheUserToTheApp() throws {
        let viewData = mapper.viewData(for: HydrationError.storageUnavailable)

        guard case .failed(let failure) = viewData.state else { throw ScreenStateMismatch.notFailed }
        XCTAssertEqual(viewData.title, "Water")
        XCTAssertEqual(failure.message, "Open the app")
        XCTAssertEqual(failure.accent, .critical)
        XCTAssertEqual(failure.accessibilityLabel, "Hydration data unavailable")
    }

    // MARK: - Helpers

    private func content(of drinks: [DrinkEntry], at hour: Int = 15) throws -> WidgetTodayViewData.Content {
        guard case .content(let content) = mapper.viewData(for: DayFixture.progress(drinks, at: hour)).state else {
            throw ScreenStateMismatch.notContent
        }
        return content
    }
}

#endif
