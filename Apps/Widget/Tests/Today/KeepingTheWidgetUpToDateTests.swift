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
        let entry = try XCTUnwrap(timeline.entries.first)
        XCTAssertEqual(try entry.content.totalText, "0.5 L")
    }

    func test_widget_whenTheDayIsRead_asksToBeWokenAQuarterOfAnHourLater() async throws {
        let timeline = await environment.widgetTimeline().makeTimeline()
        let entry = try XCTUnwrap(timeline.entries.first)

        let wakeUpAt = environment.widgetTimeline().nextRefresh(after: entry)

        XCTAssertEqual(wakeUpAt.timeIntervalSince(entry.date), 15 * 60, accuracy: 0.001)
    }

    func test_widget_whenTheDayCannotBeRead_stillShowsAFaceAndReadsAgainLater() async throws {
        let timeline = await environment.widgetTimeline(repository: FailingDrinkRepository()).makeTimeline()
        let entry = try XCTUnwrap(timeline.entries.first)

        XCTAssertEqual(try entry.failure.message, "Open the app")
        XCTAssertEqual(
            environment.widgetTimeline().nextRefresh(after: entry).timeIntervalSince(entry.date),
            15 * 60,
            accuracy: 0.001
        )
    }

    func test_widget_whenHalfAnHourHasPassed_readsTheDayAtTheNewTime() async throws {
        let firstTimeline = await environment.widgetTimeline().makeTimeline()
        let firstEntry = try XCTUnwrap(firstTimeline.entries.first)

        environment.dateProvider.advance(by: 30 * 60)
        let secondTimeline = await environment.widgetTimeline().makeTimeline()
        let secondEntry = try XCTUnwrap(secondTimeline.entries.first)

        XCTAssertEqual(secondEntry.date.timeIntervalSince(firstEntry.date), 30 * 60, accuracy: 0.001)
    }
}

#endif
