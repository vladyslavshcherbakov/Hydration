import HydrationDomain
import HydrationTestSupport
import XCTest

#if canImport(WidgetKit)
import WidgetKit

final class KeepingTheWidgetUpToDateTests: XCTestCase {
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

    func test_widget_whenTheDayIsRead_isGivenTheSingleFaceItShows() async throws {
        try await environment.log(500, at: environment.date(hour: 9))

        let timeline = await environment.widgetTimeline().makeTimeline()

        XCTAssertEqual(timeline.entries.count, 1)
        XCTAssertEqual(try XCTUnwrap(timeline.entries.first).content.totalText, "0.5 L")
    }

    func test_widget_whenTheDayIsRead_asksToBeWokenAQuarterOfAnHourLater() async throws {
        let timeline = await environment.widgetTimeline().makeTimeline()
        let readAt = try XCTUnwrap(timeline.entries.first).date

        let wakeUpAt = try XCTUnwrap(nextWake(of: timeline))
        XCTAssertEqual(wakeUpAt.timeIntervalSince(readAt), 15 * 60, accuracy: 0.001)
    }

    func test_widget_whenTheDayCannotBeRead_stillAsksToBeWoken() async throws {
        let timeline = await environment.widgetTimeline(repository: FailingDrinkRepository()).makeTimeline()

        XCTAssertEqual(try XCTUnwrap(timeline.entries.first).failure.message, "Open the app")
        XCTAssertNotNil(nextWake(of: timeline))
    }

    func test_widget_whenHalfAnHourHasPassed_asksToBeWokenHalfAnHourLaterThanBefore() async throws {
        let firstWake = try XCTUnwrap(nextWake(of: await environment.widgetTimeline().makeTimeline()))

        environment.dateProvider.advance(by: 30 * 60)
        let secondWake = try XCTUnwrap(nextWake(of: await environment.widgetTimeline().makeTimeline()))

        XCTAssertEqual(secondWake.timeIntervalSince(firstWake), 30 * 60, accuracy: 0.001)
    }

    // MARK: - Helpers

    private func nextWake(of timeline: Timeline<HydrationEntry>) -> Date? {
        guard case .after(let date) = timeline.policy else { return nil }
        return date
    }
}

#endif
