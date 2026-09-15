import HydrationRouting
import HydrationTestSupport
import XCTest
@testable import Hydration

@MainActor
final class UsingTheAppWithVoiceOverTests: XCTestCase {
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

    func test_dayScreen_whileTheDayIsBeingRead_saysItIsLoading() throws {
        let screen = environment.dayScreen()

        guard case .loading(let loading) = screen.viewData.state else { return XCTFail("expected loading") }
        XCTAssertEqual(loading.accessibilityLabel, "Loading hydration progress")
    }

    func test_dayScreen_whenTheDayIsRead_readsOutTheTotalTheGoalAndTheStatus() async throws {
        try await environment.log(1250, at: environment.date(hour: 9))
        environment.dateProvider.set(environment.date(hour: 15))

        let screen = environment.dayScreen()
        await screen.load()

        XCTAssertEqual(
            try screen.content.accessibilityLabel,
            "1.25 liters of 2.5 liters, On track, 1250 ml to go"
        )
    }

    func test_dayScreen_whenTheDayCannotBeRead_readsOutTheSameSentenceItShows() async throws {
        let broken = AppGraphEnvironment(storage: FailingDrinkRepository())
        let screen = broken.dayScreen()

        await screen.load()

        XCTAssertEqual(try screen.failure.accessibilityLabel, try screen.failure.message)
    }
}
