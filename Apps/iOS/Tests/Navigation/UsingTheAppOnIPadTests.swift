import HydrationDomain
import HydrationRouting
import HydrationTestSupport
import XCTest
@testable import Hydration

@MainActor
final class UsingTheAppOnIPadTests: XCTestCase {
    private var environment: AppGraphEnvironment!

    override func setUp() {
        super.setUp()
        environment = AppGraphEnvironment()
    }

    override func tearDown() {
        environment = nil
        super.tearDown()
    }

    func test_iPadWindow_whenOpened_showsHistoryBesideToday() async throws {
        try await environment.log(2600, at: environment.date(hour: 11))
        let coordinator = AppCoordinator(layout: .split, selectedDay: environment.today)

        XCTAssertTrue(coordinator.path.isEmpty)
        XCTAssertEqual(coordinator.detail, .history)

        let detail = environment.historyScreen(coordinator: coordinator)
        await detail.load()
        XCTAssertEqual(try detail.content.summaryText, "1 of 14 days on target")
    }

    func test_historyButton_whenTappedOnIPad_leavesTodayVisible() async throws {
        try await environment.log(600, at: environment.date(hour: 11))
        let coordinator = AppCoordinator(layout: .split, selectedDay: environment.today)
        coordinator.pop()
        let today = environment.dayScreen(coordinator: coordinator)

        today.openHistory()

        XCTAssertEqual(coordinator.detail, .history)
        XCTAssertTrue(coordinator.path.isEmpty)

        await today.load()
        XCTAssertEqual(try today.content.totalText, "0.6 L")
    }

    func test_historyScreen_whenTheWindowWidens_staysOpen() async throws {
        try await environment.log(2600, at: environment.date(hour: 11))
        let coordinator = AppCoordinator(layout: .stack, selectedDay: environment.today)
        coordinator.show(.history)
        let narrowScreen = environment.historyScreen(coordinator: coordinator)
        await narrowScreen.load()
        XCTAssertEqual(try narrowScreen.content.summaryText, "1 of 14 days on target")

        coordinator.apply(layout: .split)

        XCTAssertEqual(coordinator.visibleRoute, .history)
        let wideScreen = environment.historyScreen(coordinator: coordinator)
        await wideScreen.load()
        XCTAssertEqual(try wideScreen.content.summaryText, "1 of 14 days on target")
        XCTAssertEqual(try wideScreen.content.rows.first?.totalText, "2.6 L")
    }

    func test_selectedDay_whenTheWindowWidens_staysSelected() async throws {
        try await environment.log(2600, at: environment.date(hour: 11))
        let coordinator = AppCoordinator(layout: .stack, selectedDay: environment.today)
        let narrowScreen = environment.historyScreen(coordinator: coordinator)
        await narrowScreen.load()
        narrowScreen.select(rowID: try XCTUnwrap(try narrowScreen.content.rows[1].id))

        coordinator.apply(layout: .split)
        let wideScreen = environment.historyScreen(coordinator: coordinator)
        await wideScreen.load()

        XCTAssertEqual(try wideScreen.content.rows[1].isSelected, true)
        XCTAssertEqual(try wideScreen.content.rows.filter(\.isSelected).count, 1)
        XCTAssertEqual(try wideScreen.content.rows.first?.totalText, "2.6 L")
    }

    func test_historyScreen_whenTheWindowNarrows_staysOpen() async throws {
        try await environment.log(2600, at: environment.date(hour: 11))
        let coordinator = AppCoordinator(layout: .stack, selectedDay: environment.today)
        coordinator.show(.history)
        coordinator.apply(layout: .split)

        coordinator.apply(layout: .stack)

        XCTAssertEqual(coordinator.path, [.history])
        XCTAssertNil(coordinator.detail)

        let narrowScreen = environment.historyScreen(coordinator: coordinator)
        await narrowScreen.load()
        XCTAssertEqual(try narrowScreen.content.rows.first?.totalText, "2.6 L")
    }

    func test_todayScreen_whenAnotherWindowLogsWater_showsIt() async throws {
        let firstWindow = environment.dayScreen(coordinator: AppCoordinator(layout: .stack, selectedDay: environment.today))
        let secondWindow = environment.dayScreen(coordinator: AppCoordinator(layout: .split, selectedDay: environment.today))

        await firstWindow.quickAdd(milliliters: 600)
        await secondWindow.load()

        XCTAssertEqual(try secondWindow.content.totalText, "0.6 L")
    }

    func test_secondWindow_whenTheFirstOpensHistory_staysOnToday() async throws {
        try await environment.log(600, at: environment.date(hour: 11))
        let firstCoordinator = AppCoordinator(layout: .stack, selectedDay: environment.today)
        let secondCoordinator = AppCoordinator(layout: .stack, selectedDay: environment.today)
        let secondWindowToday = environment.dayScreen(coordinator: secondCoordinator)

        environment.dayScreen(coordinator: firstCoordinator).openHistory()

        XCTAssertEqual(firstCoordinator.path, [.history])
        XCTAssertTrue(secondCoordinator.path.isEmpty)

        await secondWindowToday.load()
        XCTAssertEqual(try secondWindowToday.content.totalText, "0.6 L")
    }

    func test_iPadHistoryList_whenLoaded_showsOneRowPerDayAndTheDaysOnTarget() async throws {
        try await environment.log(2600, at: environment.date(hour: 11))
        try await environment.log(1200, at: environment.date(hour: 12, dayOffset: -1))

        let coordinator = AppCoordinator(layout: .split, selectedDay: environment.today)
        let screen = environment.historyScreen(coordinator: coordinator)
        let controller = HistoryCollectionViewController(viewModel: screen)
        controller.loadViewIfNeeded()
        await screen.load()

        XCTAssertEqual(controller.title, "History")
        XCTAssertEqual(controller.navigationItem.prompt, "1 of 14 days on target")
        XCTAssertEqual(controller.collectionView.numberOfItems(inSection: 0), 14)
    }

    func test_widgetLink_whenTappedOnIPad_opensHistoryBesideToday() async throws {
        try await environment.log(2600, at: environment.date(hour: 11))
        let coordinator = AppCoordinator(layout: .split, selectedDay: environment.today)
        coordinator.pop()

        _ = await environment.deepLinkOpener(coordinator: coordinator)
            .open(DeepLinkMapper.url(for: .history))

        XCTAssertEqual(coordinator.detail, .history)
        XCTAssertTrue(coordinator.path.isEmpty)

        let detail = environment.historyScreen(coordinator: coordinator)
        await detail.load()
        XCTAssertEqual(try detail.content.rows.first?.totalText, "2.6 L")
    }
}
