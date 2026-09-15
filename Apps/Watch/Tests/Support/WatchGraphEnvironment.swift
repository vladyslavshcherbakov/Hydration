import Foundation
import HydrationDomain
import HydrationPairedDevice
import HydrationPersistence
import HydrationTestSupport
@testable import HydrationWatch

final class WatchGraphEnvironment {
    let graph: WatchGraph
    let storage: DrinkRepository & LocalDrinkWriter
    let pairedDevice: RecordingPairedDeviceChannel
    let dateProvider: MutableDateProvider
    let silentLog: SilentLog

    var calendar: Calendar { DayFixture.calendar }

    var locale: Locale { DayFixture.calendar.locale! }

    var today: Date { calendar.dayInterval(for: dateProvider.now()).start }

    var observedRepository: ObservedDrinkRepository { graph.observedDrinks }

    // MARK: - Public

    init(
        storage: DrinkRepository & LocalDrinkWriter = InMemoryDrinkRepository(),
        now: Date = DayFixture.moment(hour: 12),
        goal: HydrationGoal = .standard
    ) {
        let pairedDevice = RecordingPairedDeviceChannel()
        let dateProvider = MutableDateProvider(now: now)
        let log = SilentLog()

        self.storage = storage
        self.pairedDevice = pairedDevice
        self.dateProvider = dateProvider
        self.silentLog = log
        self.graph = WatchGraph(
            storage: storage,
            pairedDevice: pairedDevice,
            dateProvider: dateProvider,
            calendar: DayFixture.calendar,
            goal: goal,
            log: log
        )
    }

    func date(hour: Int, minute: Int = 0, dayOffset: Int = 0) -> Date {
        let startOfThatDay = calendar.date(byAdding: .day, value: dayOffset, to: today)!
        return calendar.date(byAdding: DateComponents(hour: hour, minute: minute), to: startOfThatDay)!
    }

    func log(_ milliliters: Int, at date: Date) async throws {
        try await observedRepository.save(
            DrinkEntry(
                id: UUID(),
                volume: Volume(milliliters: milliliters)!,
                day: calendar.dayInterval(for: date).start,
                recordedAt: date
            )
        )
    }

    func receiveFromPairedDevice(_ message: PairedDeviceMessage) async throws {
        try await pairedDevice.deliver(message)
    }

    func makeAddDrink() -> AddDrinkUseCase {
        graph.root.makeAddDrink()
    }
}
