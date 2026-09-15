import HydrationDomain
import HydrationRouting
import HydrationTestSupport
import XCTest
@testable import Hydration

@MainActor
final class OpeningTheAppFromTheWidgetTests: XCTestCase {
    private var environment: PersistenceEnvironment!

    private var coordinator: AppCoordinator!

    override func setUp() {
        super.setUp()
        environment = PersistenceEnvironment()
        coordinator = AppCoordinator(layout: .stack, selectedDay: environment.today)
    }

    override func tearDown() {
        environment = nil
        coordinator = nil
        super.tearDown()
    }

    // MARK: - Tests

    func test_widgetLink_whenTapped_opensHistory() async throws {
        try await environment.log(2600, at: environment.date(hour: 11))

        let outcome = await makeOpener().open(DeepLinkMapper.url(for: .history))

        XCTAssertEqual(outcome, .handled)
        XCTAssertEqual(coordinator.path, [.history])

        let history = environment.historyScreen(coordinator: coordinator)
        await history.load()
        XCTAssertEqual(try history.content.rows.first?.totalText, "2.6 L")
    }

    func test_todayScreen_whenTheWidgetLogsADrink_showsIt() async throws {
        _ = await makeOpener().open(DeepLinkMapper.url(for: .addDrink(milliliters: 400)))

        let today = environment.dayScreen()
        await today.load()

        XCTAssertEqual(try today.content.totalText, "0.4 L")
    }

    func test_widgetLink_whenItLogsADrink_returnsTheUserToToday() async throws {
        coordinator.show(.history)

        _ = await makeOpener().open(.addDrink(milliliters: 250))

        XCTAssertTrue(coordinator.path.isEmpty)

        let today = environment.dayScreen()
        await today.load()
        XCTAssertEqual(try today.content.totalText, "0.25 L")
    }

    func test_link_whenOpenedBeforeAnyScreenExists_stillTakesEffect() async throws {
        let opener = makeOpener()

        _ = await opener.open(.addDrink(milliliters: 500))
        _ = await opener.open(.history)

        let today = environment.dayScreen()
        await today.load()

        XCTAssertEqual(coordinator.path, [.history])
        XCTAssertEqual(try today.content.totalText, "0.5 L")
    }

    func test_todayLink_whenOpenedFromHistory_returnsTheUserToToday() async throws {
        coordinator.show(.history)

        let outcome = await makeOpener().open(DeepLinkMapper.url(for: .today))

        XCTAssertEqual(outcome, .handled)
        XCTAssertTrue(coordinator.path.isEmpty)
    }

    func test_brokenLink_whenOpened_changesNothing() async throws {
        let opener = makeOpener()
        let broken = [
            "https://hydration/history",
            "hydration://unknown",
            "hydration://add",
            "hydration://add?ml=abc",
            "hydration://add?ml=0",
            "hydration://add?ml=-250",
            "hydration://add?ml=9000",
            "hydration://add?amount=250"
        ]

        for raw in broken {
            let outcome = await opener.open(URL(string: raw)!)
            XCTAssertNil(outcome, raw)
        }

        let today = environment.dayScreen()
        await today.load()

        XCTAssertEqual(try today.content.totalText, "0 L")
        XCTAssertTrue(coordinator.path.isEmpty)
    }

    // MARK: - Helpers

    private func makeOpener() -> DeepLinkOpener {
        environment.deepLinkOpener(coordinator: coordinator)
    }
}
