import HydrationRouting
import HydrationTestSupport
import XCTest
@testable import Hydration

@MainActor
final class LeavingAScreenTests: XCTestCase {
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

    func test_dayScreen_whenClosed_stopsReadingTheDayAgain() async throws {
        let screen = environment.dayScreen()
        let watching = Task { await screen.observe() }
        try await waitFor { try screen.content.footnote == "No drinks logged yet" }

        watching.cancel()
        await watching.value
        try await environment.log(400, at: environment.date(hour: 9))

        try await Task.sleep(nanoseconds: 100_000_000)
        XCTAssertEqual(try screen.content.footnote, "No drinks logged yet")
    }

    func test_dayScreen_whenClosed_isLetGo() async throws {
        let screen = environment.dayScreen()
        let watching = Task { await screen.observe() }
        try await waitFor { try screen.content.footnote == "No drinks logged yet" }

        watching.cancel()
        await watching.value

        assertNothingHolds(screen)
    }

    func test_historyScreen_whenClosed_isLetGo() async throws {
        let screen = environment.historyScreen(coordinator: AppCoordinator(selectedDay: environment.today))
        let watching = Task { await screen.observe() }
        try await waitFor { try screen.content.rows.count == HistoryViewModel.visibleDays }

        watching.cancel()
        await watching.value

        assertNothingHolds(screen)
    }

    func test_iPadHistoryScreen_whenClosed_isLetGo() {
        let coordinator = AppCoordinator(layout: .split, selectedDay: environment.today)
        let controller = HistoryCollectionViewController(viewModel: environment.historyScreen(coordinator: coordinator))

        controller.loadViewIfNeeded()

        assertNothingHolds(controller)
    }
}
