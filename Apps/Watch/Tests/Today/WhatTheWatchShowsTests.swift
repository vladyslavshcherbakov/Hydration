import HydrationDesignSystem
import HydrationDomain
import HydrationTestSupport
import XCTest
@testable import HydrationWatch

@MainActor
final class WhatTheWatchShowsTests: XCTestCase {
    private var environment: WatchGraphEnvironment!

    override func setUp() {
        super.setUp()
        environment = WatchGraphEnvironment()
    }

    override func tearDown() {
        environment = nil
        super.tearDown()
    }

    func test_status_whenALitreIsLoggedByMidMorning_saysOnTrack() async throws {
        try await environment.log(1000, at: environment.date(hour: 9))
        environment.dateProvider.set(environment.date(hour: 10))

        let screen = environment.todayScreen()
        await screen.load()

        XCTAssertEqual(try screen.content.statusText, "On track")
        XCTAssertEqual(try screen.content.accent, .neutral)
    }

    func test_watchStatus_whenALitreIsLoggedByMidday_saysBehind() async throws {
        try await environment.log(1000, at: environment.date(hour: 9))
        environment.dateProvider.set(environment.date(hour: 15))

        let screen = environment.todayScreen()
        await screen.load()

        XCTAssertEqual(try screen.content.statusText, "250 ml behind")
        XCTAssertEqual(try screen.content.accent, .warning)
    }

    func test_status_whenTheGoalAmountIsLogged_saysTheGoalIsReached() async throws {
        try await environment.log(2500, at: environment.date(hour: 11))

        let screen = environment.todayScreen()
        await screen.load()

        XCTAssertEqual(try screen.content.totalText, "2.5")
        XCTAssertEqual(try screen.content.statusText, "Goal reached")
        XCTAssertEqual(try screen.content.accent, .positive)
    }

    func test_status_whenWellOverTheGoal_warnsTheUser() async throws {
        try await environment.log(4000, at: environment.date(hour: 11))

        let screen = environment.todayScreen()
        await screen.load()

        XCTAssertEqual(try screen.content.statusText, "Above your goal")
        XCTAssertEqual(try screen.content.accent, .critical)
    }

    func test_watchFace_beforeTheDayIsRead_isWaiting() throws {
        let screen = environment.todayScreen()

        guard case .loading(let loading) = screen.viewData.state else { return XCTFail("expected loading") }
        XCTAssertEqual(screen.viewData.title, "Water")
        XCTAssertEqual(loading.accessibilityLabel, "Loading")
    }

    func test_watchFace_whenTheDayIsRead_tellsVoiceOverTheTotalTheGoalAndTheStatus() async throws {
        try await environment.log(1250, at: environment.date(hour: 9))

        let screen = environment.todayScreen()
        await screen.load()

        XCTAssertEqual(try screen.content.accessibilityLabel, "1.25 of 2.5, On track")
    }

    func test_watchFace_whenADrinkIsRefused_saysTheLimitIsReached() async throws {
        try await environment.log(6000, at: environment.date(hour: 9))
        let screen = environment.todayScreen()
        await screen.load()

        await screen.add(milliliters: 200)

        XCTAssertEqual(try screen.failure.message, "Limit")
    }

    func test_watchFace_whenTheDataCannotBeRead_offersARetry() async throws {
        let broken = WatchGraphEnvironment(storage: FailingDrinkRepository())
        let screen = broken.todayScreen()

        await screen.load()

        XCTAssertEqual(try screen.failure.message, "Retry")
        XCTAssertEqual(try screen.failure.accent, .critical)
    }
}
