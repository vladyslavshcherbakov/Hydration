import HydrationDomain
import HydrationTestSupport
import XCTest
@testable import Hydration

@MainActor
final class SeeingChangesFromElsewhereTests: XCTestCase {
    private var environment: AppGraphEnvironment!

    override func setUp() {
        super.setUp()
        environment = AppGraphEnvironment()
    }

    override func tearDown() {
        environment = nil
        super.tearDown()
    }

    // MARK: - Tests

    func test_dayScreen_whenAnotherProcessWritesADrink_showsItWithoutBeingReopened() async throws {
        let screen = environment.dayScreen()
        let watching = Task { await screen.observe() }
        try await waitFor { try screen.content.totalText == "0 L" }

        try await environment.log(400, at: environment.date(hour: 9))

        try await waitFor { try screen.content.totalText == "0.4 L" }
        watching.cancel()
    }

    func test_dayScreen_whenADrinkIsWrittenIntoAnotherDay_staysAsItIs() async throws {
        let yesterday = environment.date(hour: 9, dayOffset: -1)
        let screen = environment.dayScreen()
        let watching = Task { await screen.observe() }
        try await waitFor { try screen.content.footnote == "No drinks logged yet" }

        try await environment.log(400, at: yesterday)

        try await Task.sleep(nanoseconds: 100_000_000)
        XCTAssertEqual(try screen.content.footnote, "No drinks logged yet")
        watching.cancel()
    }

    func test_dayScreen_whenTheWidgetWroteAndOnlyTheAnnouncementArrives_readsTheDayItShowsAgain() async throws {
        let yesterday = environment.date(hour: 0, dayOffset: -1)
        let screen = environment.dayScreen(day: yesterday)
        let watching = Task { await screen.observe() }
        try await waitFor { try screen.content.footnote == "No drinks logged yet" }

        try await environment.storage.save(
            DrinkEntry(
                id: UUID(),
                volume: Volume(milliliters: 400)!,
                day: yesterday,
                recordedAt: environment.date(hour: 9, dayOffset: -1)
            )
        )
        environment.observedRepository.noteWrittenElsewhere()

        try await waitFor { try screen.content.footnote == "1 drinks logged" }
        watching.cancel()
    }

    func test_historyScreen_whenAnotherProcessWritesADrink_showsItWithoutBeingReopened() async throws {
        let coordinator = AppCoordinator(selectedDay: environment.today)
        let screen = environment.historyScreen(coordinator: coordinator)
        let watching = Task { await screen.observe() }
        try await waitFor { try screen.content.rows.count == HistoryViewModel.visibleDays }

        try await environment.log(2600, at: environment.date(hour: 9))

        try await waitFor { try screen.content.rows.first?.totalText == "2.6 L" }
        watching.cancel()
    }
}
