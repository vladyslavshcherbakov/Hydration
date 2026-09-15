import Foundation
import HydrationDomain
import HydrationPairedDevice
import HydrationPersistence
import HydrationTestSupport
import XCTest
@testable import Hydration

final class HowTheAppIsWiredTests: XCTestCase {
    private var environment: AppGraphEnvironment!
    private var storage: InMemoryDrinkRepository!

    override func setUp() {
        super.setUp()
        storage = InMemoryDrinkRepository()
        environment = AppGraphEnvironment(storage: storage)
    }

    override func tearDown() {
        environment = nil
        storage = nil
        super.tearDown()
    }

    // MARK: - Tests

    func test_widget_whenTheWatchLogsADrink_isReloaded() async throws {
        try await environment.receiveFromPairedDevice(environment.drinkFromTheWatch(450))

        XCTAssertEqual(environment.widgetReloads.count, 1)
    }

    func test_widget_whenTheAppLogsADrink_isReloaded() async throws {
        _ = try await environment.graph.root.makeAddDrink().execute(milliliters: 250, on: DayFixture.day)

        XCTAssertEqual(environment.widgetReloads.count, 1)
    }

    func test_widget_whenADrinkIsRemoved_isReloaded() async throws {
        let progress = try await environment.graph.root.makeAddDrink().execute(milliliters: 250, on: DayFixture.day)
        let logged = try XCTUnwrap(progress.entries.first)

        _ = try await environment.graph.root.makeRemoveDrink().execute(id: logged.id, on: DayFixture.day)

        XCTAssertEqual(environment.widgetReloads.count, 2)
    }

    func test_pairedDevice_whenTheWatchLogsADrink_isNotToldAboutItAgain() async throws {
        try await environment.receiveFromPairedDevice(environment.drinkFromTheWatch(450))

        XCTAssertTrue(environment.pairedDevice.sent.isEmpty)
    }

    func test_pairedDevice_whenTheAppLogsADrink_isToldOnce() async throws {
        _ = try await environment.graph.root.makeAddDrink().execute(milliliters: 250, on: DayFixture.day)

        XCTAssertEqual(environment.pairedDevice.sentDrinks.map(\.amountML), [250])
    }

    func test_openScreens_whenTheWatchLogsADrink_areTold() async throws {
        let told = expectation(description: "the screens hear the change")
        let watching = Task { [environment] in
            for await _ in environment!.graph.root.changes.whenDrinksChange() {
                told.fulfill()
                return
            }
        }
        try await Task.sleep(nanoseconds: 50_000_000)

        try await environment.receiveFromPairedDevice(environment.drinkFromTheWatch(450))

        await fulfillment(of: [told], timeout: 1)
        watching.cancel()
    }

    func test_theDay_whenTheWatchLogsADrink_holdsIt() async throws {
        try await environment.receiveFromPairedDevice(environment.drinkFromTheWatch(450))

        XCTAssertEqual(storage.stored.map(\.volume.milliliters), [450])
    }
}
