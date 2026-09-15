import Foundation
import HydrationDomain
import HydrationTestSupport
import XCTest
@testable import HydrationPairedDevice

final class SendingToThePairedDeviceTests: XCTestCase {
    private var storage: InMemoryDrinkRepository!
    private var pairedDevice: RecordingPairedDeviceChannel!

    override func setUp() {
        super.setUp()
        storage = InMemoryDrinkRepository()
        pairedDevice = RecordingPairedDeviceChannel()
    }

    override func tearDown() {
        storage = nil
        pairedDevice = nil
        super.tearDown()
    }

    // MARK: - Tests

    func test_save_whenADrinkIsStored_sendsItOn() async throws {
        try await makeMirroring().save(DayFixture.drink(250, at: 9))

        XCTAssertEqual(pairedDevice.sentDrinks.map(\.amountML), [250])
    }

    func test_save_whenADrinkIsStored_keepsItLocallyToo() async throws {
        try await makeMirroring().save(DayFixture.drink(250, at: 9))

        XCTAssertEqual(storage.stored.count, 1)
    }

    func test_delete_whenADrinkIsRemoved_sendsTheRemovalOn() async throws {
        let drink = DayFixture.drink(250, at: 9)
        try await storage.save(drink)

        try await makeMirroring().delete(id: drink.id)

        XCTAssertEqual(pairedDevice.sentRemovals.map(\.id), [drink.id])
        XCTAssertTrue(storage.stored.isEmpty)
    }

    func test_save_whenTheStoreFails_sendsNothing() async {
        let mirroring = MirroringDrinkRepository(localStorage: FailingDrinkRepository(), pairedDevice: pairedDevice)

        _ = try? await mirroring.save(DayFixture.drink(250, at: 9))

        XCTAssertTrue(pairedDevice.sent.isEmpty)
    }

    func test_snapshot_whenTheDayHasDrinks_sendsEveryOneOfThem() async throws {
        try await storage.save(DayFixture.drink(250, at: 9))
        try await storage.save(DayFixture.drink(500, at: 11))

        await makeSnapshotSender().sendToPairedDevice()

        XCTAssertEqual(pairedDevice.sentSnapshots.count, 1)
        XCTAssertEqual(pairedDevice.sentSnapshots.first?.drinks.map(\.amountML).sorted(), [250, 500])
    }

    func test_snapshot_whenTheDayIsEmpty_sendsAPictureWithNoDrinks() async {
        await makeSnapshotSender().sendToPairedDevice()

        XCTAssertEqual(pairedDevice.sentSnapshots.count, 1)
        XCTAssertTrue(pairedDevice.sentSnapshots.first?.drinks.isEmpty == true)
    }

    func test_snapshot_whenDrinksBelongToEarlierDays_leavesThemOut() async throws {
        try await storage.save(DayFixture.drink(250, at: 9))
        try await storage.save(DayFixture.drink(900, at: 9, dayOffset: -1))

        await makeSnapshotSender().sendToPairedDevice()

        XCTAssertEqual(pairedDevice.sentSnapshots.first?.drinks.map(\.amountML), [250])
    }

    func test_snapshot_whenTheDayCannotBeRead_sendsNothing() async {
        let sender = TodaySnapshotSender(
            repository: FailingDrinkRepository(),
            pairedDevice: pairedDevice,
            currentDay: CurrentDay(dateProvider: MutableDateProvider(now: DayFixture.moment(hour: 15)), calendar: DayFixture.calendar),
            calendar: DayFixture.calendar,
            log: SilentLog()
        )

        await sender.sendToPairedDevice()

        XCTAssertTrue(pairedDevice.sent.isEmpty)
    }

    // MARK: - Helpers

    private func makeMirroring() -> MirroringDrinkRepository {
        MirroringDrinkRepository(localStorage: storage, pairedDevice: pairedDevice)
    }

    private func makeSnapshotSender() -> TodaySnapshotSender {
        TodaySnapshotSender(
            repository: storage,
            pairedDevice: pairedDevice,
            currentDay: CurrentDay(dateProvider: MutableDateProvider(now: DayFixture.moment(hour: 15)), calendar: DayFixture.calendar),
            calendar: DayFixture.calendar,
            log: SilentLog()
        )
    }
}
