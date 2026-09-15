import HydrationDesignSystem
import HydrationDomain
import HydrationRouting
import HydrationTestSupport
import XCTest
@testable import Hydration

@MainActor
final class ReachingTheGoalTests: XCTestCase {
    private var environment: PersistenceEnvironment!

    override func setUp() {
        super.setUp()
        environment = PersistenceEnvironment()
    }

    override func tearDown() {
        environment = nil
        super.tearDown()
    }

    func test_status_whenTheGoalAmountIsLogged_saysTheGoalIsReached() async throws {
        try await environment.log(2500, at: environment.date(hour: 11))

        let screen = environment.dayScreen()
        await screen.load()

        XCTAssertEqual(try screen.content.totalText, "2.5 L")
        XCTAssertEqual(try screen.content.statusText, "Daily goal reached")
        XCTAssertEqual(try screen.content.accent, .positive)
    }

    func test_todayStatus_whenJustUnderTheGoal_doesNotSayItIsReached() async throws {
        try await environment.log(2400, at: environment.date(hour: 11))

        let screen = environment.dayScreen()
        await screen.load()

        XCTAssertEqual(try screen.content.statusText, "On track, 100 ml to go")
        XCTAssertNotEqual(try screen.content.accent, .positive)
    }

    func test_status_whenWellOverTheGoal_warnsTheUser() async throws {
        try await environment.log(4000, at: environment.date(hour: 11))

        let screen = environment.dayScreen()
        await screen.load()

        XCTAssertEqual(try screen.content.statusText, "Well above your goal, consider slowing down")
        XCTAssertEqual(try screen.content.accent, .critical)
    }
}
