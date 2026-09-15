import HydrationDesignSystem
import HydrationDomain
import HydrationRouting
import HydrationTestSupport
import XCTest
@testable import Hydration

@MainActor
final class StayingOnScheduleTests: XCTestCase {
    private var environment: AppGraphEnvironment!

    override func setUp() {
        super.setUp()
        environment = AppGraphEnvironment()
    }

    override func tearDown() {
        environment = nil
        super.tearDown()
    }

    func test_todayStatus_whenItIsBeforeEightInTheMorning_expectsNothingYet() async throws {
        environment.dateProvider.set(environment.date(hour: 7))

        let screen = environment.dayScreen()
        await screen.load()

        XCTAssertEqual(try screen.content.statusText, "On track, 2500 ml to go")
        XCTAssertEqual(try screen.content.accent, .neutral)
    }

    func test_status_whenALitreIsLoggedByMidMorning_saysOnTrack() async throws {
        try await environment.log(1000, at: environment.date(hour: 9))
        environment.dateProvider.set(environment.date(hour: 10))

        let screen = environment.dayScreen()
        await screen.load()

        XCTAssertEqual(try screen.content.statusText, "On track, 1500 ml to go")
        XCTAssertEqual(try screen.content.accent, .neutral)
    }

    func test_todayStatus_whenALitreIsLoggedByMidday_saysAQuarterLitreBehind() async throws {
        try await environment.log(1000, at: environment.date(hour: 9))
        environment.dateProvider.set(environment.date(hour: 15))

        let screen = environment.dayScreen()
        await screen.load()

        XCTAssertEqual(try screen.content.statusText, "250 ml behind schedule")
        XCTAssertEqual(try screen.content.accent, .warning)
    }

    func test_todayStatus_whenItIsAfterTenInTheEvening_expectsTheWholeGoal() async throws {
        try await environment.log(1000, at: environment.date(hour: 9))
        environment.dateProvider.set(environment.date(hour: 23))

        let screen = environment.dayScreen()
        await screen.load()

        XCTAssertEqual(try screen.content.statusText, "1500 ml behind schedule")
        XCTAssertEqual(try screen.content.accent, .warning)
    }
}
