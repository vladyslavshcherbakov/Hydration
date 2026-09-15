import HydrationDomain
import HydrationPersistence
import HydrationTestSupport
import XCTest
@testable import HydrationWatch

@MainActor
final class WatchTodayViewModelTests: XCTestCase {
    private var storage: InMemoryDrinkRepository!
    private var observed: ObservedDrinkRepository!

    override func setUp() {
        super.setUp()
        storage = InMemoryDrinkRepository()
        observed = ObservedDrinkRepository(localStorage: storage)
    }

    override func tearDown() {
        storage = nil
        observed = nil
        super.tearDown()
    }

    // MARK: - Tests

    func test_watchFace_beforeAnythingIsRead_isWaiting() {
        guard case .loading = makeViewModel().viewData.state else { return XCTFail("expected loading") }
    }

    func test_watchFace_whenTheDayIsRead_showsItsTotal() async throws {
        try await observed.save(DayFixture.drink(450, at: 9))
        let screen = makeViewModel()

        await screen.load()

        XCTAssertEqual(try screen.content.totalText, "0.45")
    }

    func test_watchFace_whenTheDayCannotBeRead_offersARetry() async throws {
        let screen = makeViewModel(repository: FailingDrinkRepository())

        await screen.load()

        XCTAssertEqual(try screen.failure.message, "Retry")
    }

    func test_amount_whenAdded_showsUpInTheTotalAndIsStored() async throws {
        let screen = makeViewModel()
        await screen.load()

        await screen.add(milliliters: 350)

        XCTAssertEqual(try screen.content.totalText, "0.35")
        XCTAssertEqual(storage.stored.map(\.volume.milliliters), [350])
    }

    func test_undo_whenTheDayIsEmpty_saysThereIsNothingToUndo() async throws {
        let screen = makeViewModel()
        await screen.load()

        await screen.undoLast()

        XCTAssertEqual(try screen.failure.message, "Nothing to undo")
    }

    func test_undo_whenADrinkExists_takesItBack() async throws {
        let screen = makeViewModel()
        await screen.add(milliliters: 350)

        await screen.undoLast()

        XCTAssertEqual(try screen.content.totalText, "0")
        XCTAssertTrue(storage.stored.isEmpty)
    }

    func test_watchFace_whenSomethingElseWritesADrink_showsItWithoutBeingReopened() async throws {
        let screen = makeViewModel()
        let watching = Task { await screen.observe() }
        try await waitFor { try screen.content.totalText == "0" }

        try await observed.save(DayFixture.drink(450, at: 9))

        try await waitFor { try screen.content.totalText == "0.45" }
        watching.cancel()
    }

    // MARK: - Helpers

    private func makeViewModel(repository override: DrinkRepository? = nil) -> WatchTodayViewModel {
        let repository = override ?? observed!
        let dateProvider = MutableDateProvider(now: DayFixture.moment(hour: 15))

        return WatchTodayViewModel(
            fetchProgress: FetchDayProgressUseCase(
                repository: repository,
                dateProvider: dateProvider,
                calendar: DayFixture.calendar,
                goal: .standard
            ),
            addDrink: AddDrinkUseCase(
                repository: repository,
                dateProvider: dateProvider,
                calendar: DayFixture.calendar,
                goal: .standard,
                identifierProvider: { UUID() }
            ),
            removeLastDrink: RemoveLastDrinkUseCase(
                repository: repository,
                dateProvider: dateProvider,
                calendar: DayFixture.calendar,
                goal: .standard
            ),
            mapper: WatchTodayViewDataMapper(calendar: DayFixture.calendar, locale: DayFixture.calendar.locale!),
            currentDay: CurrentDay(dateProvider: dateProvider, calendar: DayFixture.calendar),
            calendar: DayFixture.calendar,
            changes: observed,
            log: SilentLog()
        )
    }
}
