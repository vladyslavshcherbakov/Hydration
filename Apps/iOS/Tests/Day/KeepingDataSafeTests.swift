import HydrationDesignSystem
import HydrationDomain
import HydrationRouting
import HydrationTestSupport
import XCTest
@testable import Hydration

@MainActor
final class KeepingDataSafeTests: XCTestCase {
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

    func test_todayScreen_whenAnOddAmountIsLogged_showsItExactlyAfterReload() async throws {
        try await environment.log(333, at: environment.date(hour: 9))

        let screen = environment.dayScreen()
        await screen.load()

        XCTAssertEqual(try screen.content.totalText, "0.33 L")
        XCTAssertEqual(try screen.content.entries.first?.amountText, "333 ml")
        XCTAssertEqual(try screen.content.entries.first?.timeText, "09:00")
    }

    func test_todayScreen_whenTheDataCannotBeRead_saysSo() async throws {
        let broken = AppGraphEnvironment(storage: FailingDrinkRepository())
        let screen = broken.dayScreen()

        await screen.load()

        XCTAssertEqual(try screen.failure.message, "Could not load your hydration data")
        XCTAssertEqual(try screen.failure.accent, .critical)
    }

    func test_historyScreen_whenTheDataCannotBeRead_saysSoInsteadOfShowingEmptyDays() async throws {
        let broken = AppGraphEnvironment(storage: FailingDrinkRepository())
        let screen = broken.historyScreen(coordinator: AppCoordinator(selectedDay: broken.today))

        await screen.load()

        XCTAssertEqual(try screen.failure, "Could not load history")
    }

    func test_todayScreen_beforeTheDayIsRead_saysItIsLoading() throws {
        let screen = environment.dayScreen()

        guard case .loading(let loading) = screen.viewData.state else { return XCTFail("expected loading") }
        XCTAssertEqual(screen.viewData.title, "Today")
        XCTAssertEqual(loading.message, "Loading your day…")
    }

    func test_retryButton_whenTheStorageComesBack_showsTheDayInsteadOfLoggingADrink() async throws {
        let storage = RecoveringDrinkRepository()
        let environment = AppGraphEnvironment(storage: storage)
        let screen = environment.dayScreen()
        await screen.load()
        XCTAssertEqual(try screen.failure.retryTitle, "Try again")

        storage.recover()
        await screen.load()

        XCTAssertEqual(try screen.content.totalText, "0 L")
        XCTAssertTrue(storage.saved.isEmpty)
    }

    func test_todayScreen_whenAnAmountOutsideWhatAGlassHolds_saysTheAmountIsNotValid() async throws {
        let screen = environment.dayScreen()
        await screen.load()

        await screen.quickAdd(milliliters: 0)

        XCTAssertEqual(screen.notice, "That amount is not valid")
        XCTAssertEqual(try screen.content.footnote, "No drinks logged yet")
    }
}

// MARK: - RecoveringDrinkRepository

private final class RecoveringDrinkRepository: DrinkRepository, LocalDrinkWriter, @unchecked Sendable {
    private let lock = NSLock()
    private var isWorking = false
    private var entries: [DrinkEntry] = []

    var saved: [DrinkEntry] {
        lock.lock()
        defer { lock.unlock() }
        return entries
    }

    // MARK: - Public

    func recover() {
        lock.lock()
        isWorking = true
        lock.unlock()
    }

    func entries(in range: DateInterval) async throws -> [DrinkEntry] {
        try failWhileBroken()
        return saved.filter { range.contains($0.day) }
    }

    func save(_ entry: DrinkEntry) async throws {
        try failWhileBroken()
        put(entry)
    }

    func delete(id: UUID) async throws {
        try failWhileBroken()
        remove(id)
    }

    func replaceEntries(in range: DateInterval, with arriving: [DrinkEntry]) async throws {
        try failWhileBroken()
        replace(range, with: arriving)
    }

    // MARK: - Private

    private func failWhileBroken() throws {
        lock.lock()
        defer { lock.unlock() }
        guard !isWorking else { return }
        throw HydrationError.storageUnavailable
    }

    private func put(_ entry: DrinkEntry) {
        lock.lock()
        entries.append(entry)
        lock.unlock()
    }

    private func remove(_ id: UUID) {
        lock.lock()
        entries.removeAll { $0.id == id }
        lock.unlock()
    }

    private func replace(_ range: DateInterval, with arriving: [DrinkEntry]) {
        lock.lock()
        entries.removeAll { range.contains($0.day) }
        entries.append(contentsOf: arriving)
        lock.unlock()
    }
}
