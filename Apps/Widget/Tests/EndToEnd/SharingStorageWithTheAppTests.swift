import HydrationDomain
import HydrationPersistence
import HydrationTestSupport
import XCTest

#if canImport(WidgetKit)

final class SharingStorageWithTheAppTests: XCTestCase {
    private var storeURL: URL!

    private var calendar: Calendar!

    private var locale: Locale!

    private var dateProvider: MutableDateProvider!

    override func setUp() {
        super.setUp()
        locale = Locale(identifier: "en_US_POSIX")
        calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        calendar.locale = locale
        dateProvider = MutableDateProvider(now: PersistenceEnvironment.referenceNow)
        storeURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("SharingStorageWithTheApp-\(UUID().uuidString).sqlite")
    }

    override func tearDown() {
        CoreDataStack.removeStore(at: storeURL)
        storeURL = nil
        dateProvider = nil
        calendar = nil
        locale = nil
        super.tearDown()
    }

    // MARK: - Tests
    func test_widgetTimeline_whenTheAppLogsADrink_showsTheNewTotal() async throws {
        let beforeTheDrink = await widgetTimeline().makeEntry()
        XCTAssertEqual(try beforeTheDrink.content.totalText, "0 L")

        _ = try await appAddDrink().execute(milliliters: 450, on: today)

        let afterTheDrink = await widgetTimeline().makeEntry()
        XCTAssertEqual(try afterTheDrink.content.totalText, "0.45 L")
        XCTAssertEqual(try afterTheDrink.content.goalText, "of 2.5 L")
    }

    func test_widgetTimeline_whenTheAppLogsAnEarlierDay_leavesTodayAlone() async throws {
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        _ = try await appAddDrink().execute(milliliters: 450, on: yesterday)

        let entry = await widgetTimeline().makeEntry()
        XCTAssertEqual(try entry.content.totalText, "0 L")
    }

    // MARK: - Helpers
    private var today: Date {
        calendar.dayInterval(for: dateProvider.now()).start
    }

    private func appAddDrink() -> AddDrinkUseCase {
        AddDrinkUseCase(
            repository: repositoryInItsOwnProcess(),
            dateProvider: dateProvider,
            calendar: calendar,
            goal: .standard,
            identifierProvider: { UUID() }
        )
    }

    private func widgetTimeline() -> HydrationTimelineProvider {
        HydrationTimelineProvider(
            fetchProgress: FetchDayProgressUseCase(
                repository: repositoryInItsOwnProcess(),
                dateProvider: dateProvider,
                calendar: calendar,
                goal: .standard
            ),
            presenter: WidgetTodayPresenter(calendar: calendar, locale: locale),
            dateProvider: dateProvider,
            currentDay: CurrentDay(dateProvider: dateProvider, calendar: calendar),
            log: SilentLog()
        )
    }

    private func repositoryInItsOwnProcess() -> CoreDataDrinkRepository {
        CoreDataDrinkRepository(coreDataStack: CoreDataStack(storeURL: storeURL), log: SilentLog())
    }
}

#endif
