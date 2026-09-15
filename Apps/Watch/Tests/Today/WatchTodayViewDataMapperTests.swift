import HydrationDesignSystem
import HydrationDomain
import HydrationTestSupport
import XCTest
@testable import HydrationWatch

final class WatchTodayViewDataMapperTests: XCTestCase {
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

    func test_loading_whenTheDayHasNotArrived_saysSoToVoiceOver() throws {
        guard case .loading(let loading) = mapper.loading().state else { return XCTFail("expected loading") }

        XCTAssertEqual(loading.accessibilityLabel, "Loading")
        XCTAssertEqual(mapper.loading().title, "Water")
    }

    func test_total_whenTheDayHasDrinks_isInLitresWithoutAUnit() throws {
        let content = try content(of: [DayFixture.drink(700, at: 9)])

        XCTAssertEqual(content.totalText, "0.7")
        XCTAssertEqual(content.goalText, "/ 2.5")
    }

    func test_status_whenTheDayKeepsUpWithTheClock_saysOnTrack() throws {
        let content = try content(of: [DayFixture.drink(1250, at: 9)])

        XCTAssertEqual(content.statusText, "On track")
        XCTAssertEqual(content.accent, .neutral)
    }

    func test_status_whenTheDayTrailsTheClock_saysHowFarBehind() throws {
        let content = try content(of: [DayFixture.drink(1000, at: 9)])

        XCTAssertEqual(content.statusText, "250 ml behind")
        XCTAssertEqual(content.accent, .warning)
    }

    func test_status_whenTheGoalIsMet_saysSo() throws {
        let content = try content(of: [DayFixture.drink(2500, at: 9)])

        XCTAssertEqual(content.statusText, "Goal reached")
        XCTAssertEqual(content.accent, .positive)
    }

    func test_status_whenWellOverTheGoal_warns() throws {
        let content = try content(of: [DayFixture.drink(3750, at: 9)])

        XCTAssertEqual(content.statusText, "Above your goal")
        XCTAssertEqual(content.accent, .critical)
    }

    func test_presets_whenTheDayIsEmpty_areAllOffered() throws {
        let content = try content(of: [])

        XCTAssertEqual(content.presets.map(\.title), ["+200", "+350", "+500"])
        XCTAssertEqual(content.presets.map(\.isEnabled), [true, true, true])
    }

    func test_presets_whenOnlyTheSmallestStillFits_offersThatOneAlone() throws {
        let content = try content(of: [DayFixture.drink(5800, at: 9)])

        XCTAssertEqual(content.presets.map(\.isEnabled), [true, false, false])
    }

    func test_undo_whenADrinkExists_namesTheAmountItWillRemove() throws {
        let content = try content(of: [DayFixture.drink(250, at: 9), DayFixture.drink(500, at: 11)])

        XCTAssertEqual(content.undoTitle, "Undo 500 ml")
        XCTAssertTrue(content.isUndoEnabled)
    }

    func test_undo_whenTheDayIsEmpty_saysThereIsNothingToUndo() throws {
        let content = try content(of: [])

        XCTAssertEqual(content.undoTitle, "Nothing to undo")
        XCTAssertFalse(content.isUndoEnabled)
    }

    func test_accessibilityLabel_whenTheDayIsRead_carriesTheTotalTheGoalAndTheStatus() throws {
        let content = try content(of: [DayFixture.drink(1250, at: 9)])

        XCTAssertEqual(content.accessibilityLabel, "1.25 of 2.5, On track")
    }

    func test_failure_whenTheSafetyLimitIsReached_saysLimit() {
        XCTAssertEqual(failure(for: HydrationError.safetyLimitReached)?.message, "Limit")
    }

    func test_failure_whenThereIsNothingToUndo_saysSo() {
        XCTAssertEqual(failure(for: HydrationError.nothingToRemove)?.message, "Nothing to undo")
    }

    func test_failure_whenTheDayCannotBeRead_offersARetry() {
        XCTAssertEqual(failure(for: HydrationError.storageUnavailable)?.message, "Retry")
        XCTAssertEqual(failure(for: HydrationError.storageUnavailable)?.accent, .critical)
    }

    // MARK: - Helpers

    private func content(of drinks: [DrinkEntry], at hour: Int = 15) throws -> WatchTodayViewData.Content {
        let viewData = mapper.viewData(for: DayFixture.progress(drinks, at: hour))
        guard case .content(let content) = viewData.state else { throw ScreenStateMismatch.notContent }
        return content
    }

    private func failure(for error: Error) -> WatchTodayViewData.Failure? {
        guard case .failed(let failure) = mapper.viewData(for: error).state else { return nil }
        return failure
    }
}
