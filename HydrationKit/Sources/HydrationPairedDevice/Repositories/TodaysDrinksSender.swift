import Foundation
import HydrationDomain

public final class TodaysDrinksSender: Sendable {
    private let repository: DrinkRepository
    private let pairedDevice: PairedDeviceChannel
    private let currentDay: CurrentDay
    private let calendar: Calendar
    private let log: HydrationLog

    public init(
        repository: DrinkRepository,
        pairedDevice: PairedDeviceChannel,
        currentDay: CurrentDay,
        calendar: Calendar,
        log: HydrationLog
    ) {
        self.repository = repository
        self.pairedDevice = pairedDevice
        self.currentDay = currentDay
        self.calendar = calendar
        self.log = log
    }

    public func sendToPairedDevice() async {
        let day = currentDay.start()
        do {
            let drinksOfThatDay = try await repository.entries(of: day, in: calendar)
            log.write(.info, "sending \(drinksOfThatDay.count) drinks of \(day) to the paired device")
            for drink in drinksOfThatDay {
                pairedDevice.send(DrinkChangeMessageMapper.message(forLogging: drink))
            }
        } catch {
            log.write(.error, "today's drinks could not be read for the paired device: \(error)")
        }
    }
}
