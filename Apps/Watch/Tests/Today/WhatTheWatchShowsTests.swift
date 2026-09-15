import HydrationDesignSystem
import HydrationDomain
import HydrationTestSupport
import XCTest
@testable import HydrationWatch

@MainActor
final class WhatTheWatchShowsTests: XCTestCase {
    private var environment: PersistenceEnvironment!

    override func setUp() {
        super.setUp()
        environment = PersistenceEnvironment()
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

    func test_watchFace_whenTheDataCannotBeRead_offersARetry() async throws {
        let screen = environment.todayScreen(repository: FailingDrinkRepository())

        await screen.load()

        XCTAssertEqual(try screen.failure.message, "Retry")
        XCTAssertEqual(try screen.failure.accent, .critical)
    }
}
