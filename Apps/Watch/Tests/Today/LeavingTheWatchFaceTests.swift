import HydrationTestSupport
import XCTest
@testable import HydrationWatch

@MainActor
final class LeavingTheWatchFaceTests: XCTestCase {
    private var environment: WatchGraphEnvironment!

    override func setUp() {
        super.setUp()
        environment = WatchGraphEnvironment()
    }

    override func tearDown() {
        environment = nil
        super.tearDown()
    }

    // MARK: - Tests

    func test_watchFace_whenClosed_stopsReadingTheDayAgain() async throws {
        let screen = environment.todayScreen()
        let watching = Task { await screen.observe() }
        try await waitFor { try screen.content.totalText == "0" }

        watching.cancel()
        await watching.value
        try await environment.log(450, at: environment.date(hour: 9))

        try await Task.sleep(nanoseconds: 100_000_000)
        XCTAssertEqual(try screen.content.totalText, "0")
    }

    func test_watchFace_whenClosed_isLetGo() async throws {
        let screen = environment.todayScreen()
        let watching = Task { await screen.observe() }
        try await waitFor { try screen.content.totalText == "0" }

        watching.cancel()
        await watching.value

        assertNothingHolds(screen)
    }
}
