import HydrationDomain
import XCTest

final class DailySummaryTests: XCTestCase {

    // MARK: - Tests

    func test_fraction_whenHalfTheGoalIsLogged_isAHalf() throws {
        let summary = DailySummary(day: DayFixture.day, total: try XCTUnwrap(Volume(milliliters: 1250)), goal: .standard)

        XCTAssertEqual(summary.fraction, 0.5)
    }

    func test_fraction_whenTheGoalIsPassed_stopsAtOne() throws {
        let summary = DailySummary(day: DayFixture.day, total: try XCTUnwrap(Volume(milliliters: 4000)), goal: .standard)

        XCTAssertEqual(summary.fraction, 1)
    }

    func test_isGoalReached_whenExactlyTheGoalIsLogged_isTrue() throws {
        let summary = DailySummary(day: DayFixture.day, total: try XCTUnwrap(Volume(milliliters: 2500)), goal: .standard)

        XCTAssertTrue(summary.isGoalReached)
    }

    func test_isGoalReached_whenOneMillilitreShort_isFalse() throws {
        let summary = DailySummary(day: DayFixture.day, total: try XCTUnwrap(Volume(milliliters: 2499)), goal: .standard)

        XCTAssertFalse(summary.isGoalReached)
    }
}
