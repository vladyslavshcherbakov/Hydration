import HydrationDomain
import HydrationRouting
import HydrationTestSupport
import XCTest
@testable import Hydration

@MainActor
final class SharingOneStoreTests: XCTestCase {
    private var environment: EndToEndEnvironment!

    override func setUp() {
        super.setUp()
        environment = EndToEndEnvironment()
    }

    override func tearDown() {
        environment.removeStore()
        environment = nil
        super.tearDown()
    }

    // MARK: - Tests

    func test_todayScreen_whenASecondCopyOfTheAppLogsADrink_showsItAndSoDoesHistory() async throws {
        let secondCopy = environment.makeCompositionRoot()
        let app = environment.makeCompositionRoot()

        _ = try await secondCopy.makeAddDrink().execute(milliliters: 1500, on: secondCopy.makeCurrentDay().start())

        let today = todayScreen(app)
        await today.load()
        XCTAssertEqual(try today.content.totalText, "1.5 L")

        let history = HistoryViewModel(
            fetchHistory: app.makeFetchHistory(),
            presenter: HistoryPresenter(calendar: environment.calendar, locale: environment.locale, today: app.makeCurrentDay().start()),
            changes: app.changes,
            log: environment.log,
            selectedDay: app.makeCurrentDay().start(),
            onDaySelected: { _ in }
        )
        await history.load()
        XCTAssertEqual(history.state.rows.first?.totalText, "1.5 L")
    }

    func test_todayScreen_whenTheAppIsReopened_stillShowsTheWater() async throws {
        let firstLaunch = todayScreen(environment.makeCompositionRoot())
        await firstLaunch.quickAdd(milliliters: 500)
        await firstLaunch.quickAdd(milliliters: 250)
        XCTAssertEqual(try firstLaunch.content.totalText, "0.75 L")

        let secondLaunch = todayScreen(environment.makeCompositionRoot())
        await secondLaunch.load()

        XCTAssertEqual(try secondLaunch.content.totalText, "0.75 L")
        XCTAssertEqual(try secondLaunch.content.entries.count, 2)
    }

    func test_dailyLimit_whenTwoCopiesOfTheAppAreRunning_stillHolds() async throws {
        let today = todayScreen(environment.makeCompositionRoot())
        for _ in 0..<6 {
            await today.quickAdd(milliliters: 1000)
            environment.dateProvider.advance(by: 60)
        }

        do {
            let another = environment.makeCompositionRoot()
            _ = try await another.makeAddDrink().execute(milliliters: 250, on: another.makeCurrentDay().start())
            XCTFail("Expected the drink to be refused")
        } catch {
            XCTAssertEqual(error as? HydrationError, .safetyLimitReached)
        }

        XCTAssertEqual(try today.content.totalText, "6 L")
    }

    // MARK: - Helpers

    private func todayScreen(_ root: CompositionRoot) -> DayViewModel {
        DayViewModel(
            day: root.makeCurrentDay().start(),
            fetchProgress: root.makeFetchDay(),
            addDrink: root.makeAddDrink(),
            removeDrink: root.makeRemoveDrink(),
            mapper: DayViewDataMapper(calendar: environment.calendar, locale: environment.locale),
            changes: root.changes,
            log: environment.log,
            onHistoryRequested: {}
        )
    }
}
