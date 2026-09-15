import HydrationDomain
import XCTest

final class DailyProgressTests: XCTestCase {

    // MARK: - Tests

    func test_total_whenSeveralDrinksAreLogged_addsThemUp() {
        let progress = DayFixture.progress([DayFixture.drink(250, at: 9), DayFixture.drink(500, at: 11)], at: 15)

        XCTAssertEqual(progress.total.milliliters, 750)
    }

    func test_fraction_whenTheGoalIsPassed_stopsAtOne() {
        let progress = DayFixture.progress([DayFixture.drink(4000, at: 9)], at: 15)

        XCTAssertEqual(progress.fraction, 1)
    }

    func test_expectedVolume_whenHalfTheActiveDayHasPassed_isHalfTheGoal() {
        let progress = DayFixture.progress([], at: 15)

        XCTAssertEqual(progress.expectedVolume.milliliters, 1250)
    }

    func test_expectedVolume_whenTheActiveDayHasNotStarted_isNothing() {
        let progress = DayFixture.progress([], at: 7)

        XCTAssertEqual(progress.expectedVolume, .zero)
    }

    func test_expectedVolume_whenTheActiveDayIsOver_isTheWholeGoal() {
        let progress = DayFixture.progress([], at: 23)

        XCTAssertEqual(progress.expectedVolume.milliliters, 2500)
    }

    func test_expectedVolume_whenTheDayIsNotToday_isTheWholeGoal() {
        let progress = DayFixture.progress([], at: 9, dayOffset: -1)

        XCTAssertEqual(progress.expectedVolume.milliliters, 2500)
    }

    func test_status_whenTheDayKeepsUpWithTheClock_isOnTrack() {
        let progress = DayFixture.progress([DayFixture.drink(1250, at: 9)], at: 15)

        XCTAssertEqual(progress.status, .onTrack)
        XCTAssertEqual(progress.deficit, .zero)
    }

    func test_status_whenTheDayTrailsTheClock_isBehindByTheDifference() {
        let progress = DayFixture.progress([DayFixture.drink(1000, at: 9)], at: 15)

        XCTAssertEqual(progress.status, .behind)
        XCTAssertEqual(progress.deficit.milliliters, 250)
    }

    func test_status_whenTheGoalIsMet_isReached() {
        let progress = DayFixture.progress([DayFixture.drink(2500, at: 9)], at: 15)

        XCTAssertEqual(progress.status, .reached)
    }

    func test_status_whenHalfAgainTheGoalIsLogged_isExcessive() {
        let progress = DayFixture.progress([DayFixture.drink(3750, at: 9)], at: 15)

        XCTAssertEqual(progress.status, .excessive)
    }

    func test_remaining_whenPartOfTheGoalIsLogged_isWhatIsLeft() {
        let progress = DayFixture.progress([DayFixture.drink(1000, at: 9)], at: 15)

        XCTAssertEqual(progress.remaining.milliliters, 1500)
    }

    func test_canAddMore_whenTheSafetyLimitIsReached_isFalse() {
        let progress = DayFixture.progress([DayFixture.drink(6000, at: 9)], at: 15)

        XCTAssertFalse(progress.canAddMore)
    }

    func test_lastEntry_whenDrinksArriveOutOfOrder_isTheLatestOne() {
        let progress = DayFixture.progress([DayFixture.drink(500, at: 18), DayFixture.drink(250, at: 9)], at: 20)

        XCTAssertEqual(progress.lastEntry?.volume.milliliters, 500)
    }

    func test_lastEntry_whenNothingIsLogged_isNothing() {
        XCTAssertNil(DayFixture.progress([], at: 15).lastEntry)
    }
}
