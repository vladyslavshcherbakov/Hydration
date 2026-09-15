import HydrationDomain
import HydrationTestSupport
import XCTest
@testable import HydrationWatch

@MainActor
final class LoggingOnTheWatchTests: XCTestCase {
    private var environment: PersistenceEnvironment!

    override func setUp() {
        super.setUp()
        environment = PersistenceEnvironment()
    }

    override func tearDown() {
        environment = nil
        super.tearDown()
    }

    func test_watchFace_whenOpened_offersThreeFixedAmounts() async throws {
        let screen = environment.todayScreen()
        await screen.load()

        XCTAssertEqual(try screen.content.presets.map(\.title), ["+200", "+350", "+500"])
        XCTAssertEqual(try screen.content.presets.map(\.isEnabled), [true, true, true])
    }

    func test_amountButton_whenTapped_addsItToTheDay() async throws {
        let screen = environment.todayScreen()

        await screen.add(milliliters: 200)
        environment.dateProvider.advance(by: 60)
        await screen.add(milliliters: 500)

        XCTAssertEqual(try screen.content.totalText, "0.7")
        XCTAssertEqual(try screen.content.goalText, "/ 2.5")
    }

    func test_total_whenShownOnTheWatch_keepsTwoDecimals() async throws {
        try await environment.log(1234, at: environment.date(hour: 9))

        let screen = environment.todayScreen()
        await screen.load()

        XCTAssertEqual(try screen.content.totalText, "1.23")
    }

    func test_undo_whenTappedAfterADrink_removesIt() async throws {
        let screen = environment.todayScreen()
        await screen.add(milliliters: 200)
        environment.dateProvider.advance(by: 60)
        await screen.add(milliliters: 500)

        await screen.undoLast()

        XCTAssertEqual(try screen.content.totalText, "0.2")
        XCTAssertEqual(try screen.content.undoTitle, "Undo 200 ml")
    }

    func test_undoButton_whenADrinkExists_namesTheAmountItWillRemove() async throws {
        let screen = environment.todayScreen()
        await screen.add(milliliters: 500)

        XCTAssertEqual(try screen.content.undoTitle, "Undo 500 ml")
        XCTAssertTrue(try screen.content.isUndoEnabled)
    }

    func test_undoButton_whenNothingIsLogged_isDisabled() async throws {
        let screen = environment.todayScreen()
        await screen.load()
        XCTAssertFalse(try screen.content.isUndoEnabled)

        await screen.undoLast()

        XCTAssertEqual(try screen.failure.message, "Nothing to undo")
    }

    func test_amountButtons_whenTheyWouldBreachTheDailyLimit_areDisabled() async throws {
        let addDrink = environment.makeAddDrink()
        for _ in 0..<5 {
            _ = try await addDrink.execute(milliliters: 1000, on: environment.today)
            environment.dateProvider.advance(by: 60)
        }
        _ = try await addDrink.execute(milliliters: 700, on: environment.today)

        let screen = environment.todayScreen()
        await screen.load()

        XCTAssertEqual(try screen.content.presets.map(\.isEnabled), [true, false, false])
    }
}
