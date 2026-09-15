import Foundation
import HydrationDomain
import HydrationPairedDevice
import HydrationTestSupport
@testable import Hydration

final class AppGraphEnvironment {
    let graph: AppGraph
    let storage: InMemoryDrinkRepository
    let pairedDevice: RecordingPairedDeviceChannel
    let widgetReloads: CallCounter

    // MARK: - Public

    init(now: Date = DayFixture.moment(hour: 15)) {
        let storage = InMemoryDrinkRepository()
        let pairedDevice = RecordingPairedDeviceChannel()
        let widgetReloads = CallCounter()

        self.storage = storage
        self.pairedDevice = pairedDevice
        self.widgetReloads = widgetReloads
        self.graph = AppGraph(
            storage: storage,
            pairedDevice: pairedDevice,
            reloadWidget: { widgetReloads.increment() },
            dateProvider: MutableDateProvider(now: now),
            log: SilentLog()
        )
    }

    func receiveFromPairedDevice(_ message: PairedDeviceMessage) async throws {
        try await pairedDevice.deliver(message)
    }

    func drinkFromTheWatch(_ milliliters: Int, at hour: Int = 11) -> PairedDeviceMessage {
        PairedDeviceMessage(
            content: .drinkLogged(
                DrinkMessage(
                    id: UUID(),
                    amountML: milliliters,
                    day: DayFixture.day,
                    recordedAt: DayFixture.moment(hour: hour)
                )
            )
        )
    }
}
