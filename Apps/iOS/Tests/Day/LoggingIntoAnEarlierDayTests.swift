import HydrationDomain
import HydrationTestSupport
import XCTest
@testable import Hydration

@MainActor
final class LoggingIntoAnEarlierDayTests: XCTestCase {
    private var environment: PersistenceEnvironment!

    override func setUp() {
        super.setUp()
        environment = PersistenceEnvironment()
    }

    override func tearDown() {
        environment = nil
        super.tearDown()
    }

    // MARK: - Tests
    func test_quickAdd_whenAnEarlierDayIsOpen_addsToThatDayOnly() async throws {
        let earlier = environment.dayScreen(day: yesterday)
        await earlier.load()

        await earlier.quickAdd()

        XCTAssertEqual(try earlier.content.totalText, "0.25 L")

        let today = environment.dayScreen()
        await today.load()
        XCTAssertEqual(try today.content.totalText, "0 L")
    }

    func test_earlierDayEntry_whenRecordedOnAnotherDay_showsTheDateItWasRecorded() async throws {
        let earlier = environment.dayScreen(day: yesterday)
        await earlier.load()

        await earlier.quickAdd()

        XCTAssertEqual(try earlier.content.entries.first?.timeText, "14 Nov, 12:00")
    }

    func test_dayTitle_whenAnEarlierDayIsOpen_showsThatDate() async throws {
        let earlier = environment.dayScreen(day: yesterday)

        await earlier.load()

        XCTAssertEqual(earlier.state.title, "13 Nov")
    }

    func test_dayStatus_whenAnEarlierDayIsShortOfTheGoal_expectsTheWholeGoal() async throws {
        try await environment.log(1000, at: environment.date(hour: 9, dayOffset: -1))

        let earlier = environment.dayScreen(day: yesterday)
        await earlier.load()

        XCTAssertEqual(try earlier.content.statusText, "1500 ml behind schedule")
    }

    func test_dailyLimit_whenAnEarlierDayIsAlreadyFull_refusesMore() async throws {
        for hour in 0..<6 {
            try await environment.log(1000, at: environment.date(hour: hour, dayOffset: -1))
        }

        let earlier = environment.dayScreen(day: yesterday)
        await earlier.load()
        await earlier.quickAdd()

        XCTAssertEqual(try earlier.failure.message, "You have reached the daily safety limit")
    }

    // MARK: - Helpers
    private var yesterday: Date {
        environment.date(hour: 0, dayOffset: -1)
    }
}
