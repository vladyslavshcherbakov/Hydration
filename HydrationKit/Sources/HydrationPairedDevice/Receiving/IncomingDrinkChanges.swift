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
        pairedDevice.startReceiving { [self] message in
            await apply(message)
        }
    }

    private func apply(_ message: PairedDeviceMessage) async {
        switch message {
        case .change(let change): await applyChange(change)
        case .daySnapshot(let snapshot): await applySnapshot(snapshot)
        }
    }

    private func applyChange(_ message: DrinkChangeMessage) async {
        let change: DrinkChange
        do {
            change = try DrinkChangeMessageMapper.change(from: message)
        } catch {
            log.write(.warning, "change from the paired device dropped, it could not be read: \(error), message was \(message.dictionary)")
            return
        }

        do {
            try await store(change)
        } catch {
            log.write(.error, "change \(change) from the paired device could not be stored: \(error)")
        }
    }

    private func applySnapshot(_ message: DaySnapshotMessage) async {
        let snapshot: DaySnapshot
        do {
            snapshot = try DaySnapshotMessageMapper.snapshot(from: message)
        } catch {
            log.write(.warning, "the paired device's picture of a day was dropped, it could not be read: \(error), message was \(message.dictionary)")
            return
        }

        do {
            try await localStorage.replaceEntries(in: calendar.dayInterval(for: snapshot.day), with: snapshot.drinks)
            log.write(.info, "\(snapshot.day) now holds the paired device's picture of it: \(snapshot.drinks.count) drinks")
        } catch {
            log.write(.error, "\(snapshot.day) could not be replaced by the paired device's picture of it: \(error)")
        }
    }

    private func store(_ change: DrinkChange) async throws {
        switch change {
        case .logged(let entry):
            try await localStorage.save(entry)
            log.write(.info, "stored \(entry.volume.milliliters) ml from the paired device, drink \(entry.id) of \(entry.day)")
        case .removed(let id):
            try await localStorage.delete(id: id)
            log.write(.info, "removed the drink \(id) the paired device deleted")
        }
    }
}
