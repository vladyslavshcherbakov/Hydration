import HydrationDomain
import HydrationTestSupport
import XCTest

#if canImport(WidgetKit)
import WidgetKit
#endif

@MainActor
final class CheckingTheWidgetTests: XCTestCase {
    private var environment: PersistenceEnvironment!

    override func setUp() {
        super.setUp()
        environment = PersistenceEnvironment()
    }

    override func tearDown() {
        environment = nil
        super.tearDown()
    }

    #if canImport(WidgetKit)
    func test_widget_whenDrinksAreLogged_showsTheTotalAgainstTheGoal() async throws {
        try await environment.log(1500, at: environment.date(hour: 11))

        let entry = await environment.widgetTimeline().makeEntry()

        XCTAssertEqual(entry.state.totalText, "1.5 L")
        XCTAssertEqual(entry.state.goalText, "of 2.5 L")
        XCTAssertEqual(entry.state.fraction, 0.6, accuracy: 0.0001)
    }

    func test_widget_whenTheDayIsEmpty_showsZero() async throws {
        let entry = await environment.widgetTimeline().makeEntry()

        XCTAssertEqual(entry.state.totalText, "0 L")
        XCTAssertEqual(entry.state.fraction, 0)
    }

    func test_widget_whenItRefreshes_showsTheTimeItWasUpdated() async throws {
        try await environment.log(500, at: environment.date(hour: 9))

        let entry = await environment.widgetTimeline().makeEntry()

        XCTAssertEqual(entry.state.footnote, "Updated 12:00")
    }

    func test_widget_whenQuickAddIsAvailable_offersASingleQuarterLitreButton() async throws {
        try await environment.log(500, at: environment.date(hour: 9))

        let entry = await environment.widgetTimeline().makeEntry()

        XCTAssertEqual(entry.state.quickAddTitle, "+250")
        XCTAssertTrue(entry.state.isQuickAddEnabled)
    }

    func test_widgetStatus_whenBehindSchedule_showsTheMillilitresBehind() async throws {
        try await environment.log(1000, at: environment.date(hour: 9))
        environment.dateProvider.set(environment.date(hour: 15))

        let entry = await environment.widgetTimeline().makeEntry()

        XCTAssertEqual(entry.state.statusText, "250 ml behind")
        XCTAssertEqual(entry.state.accent, .warning)
    }

    func test_widgetStatus_whenTheGoalIsReached_saysSo() async throws {
        try await environment.log(2500, at: environment.date(hour: 11))

        let entry = await environment.widgetTimeline().makeEntry()

        XCTAssertEqual(entry.state.statusText, "Goal reached")
        XCTAssertEqual(entry.state.accent, .positive)
    }

    func test_widget_whenTheDataCannotBeRead_asksTheUserToOpenTheApp() async throws {
        let entry = await environment.widgetTimeline(repository: FailingDrinkRepository()).makeEntry()

        XCTAssertEqual(entry.state.statusText, "Open the app")
        XCTAssertEqual(entry.state.accent, .critical)
        XCTAssertFalse(entry.state.isQuickAddEnabled)
    }
    #endif
}
