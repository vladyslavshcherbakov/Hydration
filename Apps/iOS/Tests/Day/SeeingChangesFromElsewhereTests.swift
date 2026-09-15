import HydrationDomain
import HydrationTestSupport
import XCTest
@testable import Hydration

@MainActor
final class SeeingChangesFromElsewhereTests: XCTestCase {
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
    func test_dayScreen_whenAnotherProcessWritesADrink_showsItWithoutBeingReopened() async throws {
        let screen = environment.dayScreen()
        let watching = Task { await screen.observe() }
        try await waitFor { screen.state.totalText == "0 L" }

        try await environment.log(400, at: environment.date(hour: 9))

        try await waitFor { screen.state.totalText == "0.4 L" }
        watching.cancel()
    }

    func test_historyScreen_whenAnotherProcessWritesADrink_showsItWithoutBeingReopened() async throws {
        let coordinator = AppCoordinator(selectedDay: environment.today)
        let screen = environment.historyScreen(coordinator: coordinator)
        let watching = Task { await screen.observe() }
        try await waitFor { screen.state.rows.count == HistoryViewModel.visibleDays }

        try await environment.log(2600, at: environment.date(hour: 9))

        try await waitFor { screen.state.rows.first?.totalText == "2.6 L" }
        watching.cancel()
    }

    // MARK: - Helpers
    private func waitFor(
        _ condition: () -> Bool,
        within attempts: Int = 200,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async throws {
        for _ in 0..<attempts {
            if condition() { return }
            try await Task.sleep(nanoseconds: 10_000_000)
        }
        XCTFail("the screen never reached the expected state", file: file, line: line)
    }
}
