import HydrationDomain
import HydrationTestSupport
import XCTest

final class DrinkChangeTests: XCTestCase {

    // MARK: - Tests

    func test_change_whenItIsOnTheDayAsked_touchesIt() {
        XCTAssertTrue(DrinkChange.onDay(DayFixture.day).touches(today))
    }

    func test_change_whenItIsOnAnotherDay_doesNotTouchTheDayAsked() {
        let yesterday = DayFixture.calendar.date(byAdding: .day, value: -1, to: DayFixture.day)!

        XCTAssertFalse(DrinkChange.onDay(yesterday).touches(today))
    }

    func test_change_whenTheDayIsUnknown_touchesEveryDay() {
        let yesterday = DayFixture.calendar.date(byAdding: .day, value: -1, to: DayFixture.day)!

        XCTAssertTrue(DrinkChange.onAnUnknownDay.touches(today))
        XCTAssertTrue(DrinkChange.onAnUnknownDay.touches(DayFixture.calendar.dayInterval(for: yesterday)))
    }

    func test_change_whenTheDayAskedAboutIsAWholeFortnight_touchesAnyDayInIt() {
        let fortnightAgo = DayFixture.calendar.date(byAdding: .day, value: -13, to: DayFixture.day)!
        let fortnight = DateInterval(start: fortnightAgo, end: today.end)
        let lastWeek = DayFixture.calendar.date(byAdding: .day, value: -6, to: DayFixture.day)!

        XCTAssertTrue(DrinkChange.onDay(lastWeek).touches(fortnight))
        XCTAssertFalse(DrinkChange.onDay(DayFixture.moment(hour: 9, dayOffset: -20)).touches(fortnight))
    }

    // MARK: - Helpers

    private var today: DateInterval {
        DayFixture.calendar.dayInterval(for: DayFixture.day)
    }
}
