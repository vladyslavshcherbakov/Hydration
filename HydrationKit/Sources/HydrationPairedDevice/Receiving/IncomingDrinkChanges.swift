import Foundation
import HydrationDomain

public final class IncomingDrinkChanges: Sendable {
    private let localStorage: LocalDrinkWriter
    private let pairedDevice: PairedDeviceChannel
    private let calendar: Calendar
    private let log: HydrationLog

    public init(localStorage: LocalDrinkWriter, pairedDevice: PairedDeviceChannel, calendar: Calendar, log: HydrationLog) {
        self.localStorage = localStorage
        self.pairedDevice = pairedDevice
        self.calendar = calendar
        self.log = log
    }

    public func start() {
        pairedDevice.startReceiving { [self] payload in
            await apply(payload)
        }
    }

    private func apply(_ payload: Data) async {
        let message: PairedDeviceMessage
        do {
            message = try PairedDeviceMessageCoder.decode(payload)
        } catch {
            log.write(.warning, "a message from the paired device was dropped, it could not be read: \(error)")
            return
        }

        switch message.content {
        case .drinkLogged(let drink): await store(drink)
        case .drinkRemoved(let removal): await remove(removal)
        case .daySnapshot(let day): await replace(day)
        }
    }

    private func store(_ message: DrinkMessage) async {
        let entry: DrinkEntry
        do {
            entry = try DrinkChangeMapper.entry(from: message)
        } catch {
            log.write(.warning, "the drink \(message.id) from the paired device was dropped, it could not be read: \(error)")
            return
        }

        do {
            try await localStorage.save(entry)
            log.write(.info, "stored \(entry.volume.milliliters) ml from the paired device, drink \(entry.id) of \(entry.day)")
        } catch {
            log.write(.error, "the drink \(entry.id) from the paired device could not be stored: \(error)")
        }
    }

    private func remove(_ message: DrinkRemovalMessage) async {
        do {
            try await localStorage.delete(id: message.id)
            log.write(.info, "removed the drink \(message.id) the paired device deleted")
        } catch {
            log.write(.error, "the drink \(message.id) the paired device deleted could not be removed: \(error)")
        }
    }

    private func replace(_ message: DayOfDrinksMessage) async {
        let drinks: [DrinkEntry]
        do {
            drinks = try message.drinks.map(DrinkChangeMapper.entry(from:))
        } catch {
            log.write(.warning, "the paired device's picture of \(message.day) was dropped, it could not be read: \(error)")
            return
        }

        do {
            try await localStorage.replaceEntries(in: calendar.dayInterval(for: message.day), with: drinks)
            log.write(.info, "\(message.day) now holds the paired device's picture of it: \(drinks.count) drinks")
        } catch {
            log.write(.error, "\(message.day) could not be replaced by the paired device's picture of it: \(error)")
        }
    }
}
