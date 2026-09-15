import HydrationDomain
import HydrationTestSupport
import XCTest

final class ReadingTheDayAndHistoryTests: XCTestCase {
    private var repository: InMemoryDrinkRepository!

    override func setUp() {
        super.setUp()
        repository = InMemoryDrinkRepository()
    }

    override func tearDown() {
        repository = nil
        super.tearDown()
    }

    // MARK: - Tests

    func test_fetchDay_whenDrinksBelongToOtherDays_countsOnlyTheDayAsked() async throws {
        try await repository.save(DayFixture.drink(250, at: 9))
        try await repository.save(DayFixture.drink(500, at: 9, dayOffset: -1))

        let progress = try await makeFetchDay().execute(day: DayFixture.day)

        XCTAssertEqual(progress.total.milliliters, 250)
    }

    func test_fetchDay_whenItIsRead_judgesTheDayAgainstTheCurrentMoment() async throws {
        try await repository.save(DayFixture.drink(1000, at: 9))

        let progress = try await makeFetchDay().execute(day: DayFixture.day)

        XCTAssertEqual(progress.evaluatedAt, DayFixture.moment(hour: 15))
        XCTAssertEqual(progress.status, .behind)
    }

    func test_fetchHistory_whenNoDaysAreAsked_returnsNothing() async throws {
        let summaries = try await makeFetchHistory().execute(days: 0)

        XCTAssertTrue(summaries.isEmpty)
    }

    func test_fetchHistory_whenThreeDaysAreAsked_returnsThemNewestFirst() async throws {
        let summaries = try await makeFetchHistory().execute(days: 3)

        XCTAssertEqual(summaries.count, 3)
        XCTAssertEqual(summaries.map(\.day), [
            DayFixture.day,
            DayFixture.calendar.date(byAdding: .day, value: -1, to: DayFixture.day)!,
            DayFixture.calendar.date(byAdding: .day, value: -2, to: DayFixture.day)!
        ])
    }

    func test_fetchHistory_whenADayHasDrinks_totalsThatDayOnly() async throws {
        try await repository.save(DayFixture.drink(250, at: 9))
        try await repository.save(DayFixture.drink(500, at: 11))
        try await repository.save(DayFixture.drink(1000, at: 9, dayOffset: -1))

        let summaries = try await makeFetchHistory().execute(days: 3)

        XCTAssertEqual(summaries[0].total.milliliters, 750)
        XCTAssertEqual(summaries[1].total.milliliters, 1000)
        XCTAssertEqual(summaries[2].total, .zero)
    }

    func test_fetchHistory_whenADayIsOutsideTheWindow_isLeftOut() async throws {
        try await repository.save(DayFixture.drink(1000, at: 9, dayOffset: -5))

        let summaries = try await makeFetchHistory().execute(days: 3)

        XCTAssertTrue(summaries.allSatisfy { $0.total == .zero })
    }

    // MARK: - Helpers

    private func makeFetchDay() -> FetchDayProgressUseCase {
        FetchDayProgressUseCase(
            repository: repository,
            dateProvider: MutableDateProvider(now: DayFixture.moment(hour: 15)),
            calendar: DayFixture.calendar,
            goal: .standard
        )
    }

    private func makeFetchHistory() -> FetchHistoryUseCase {
        FetchHistoryUseCase(
            repository: repository,
            dateProvider: MutableDateProvider(now: DayFixture.moment(hour: 15)),
            calendar: DayFixture.calendar,
            goal: .standard
        )
    }
}
