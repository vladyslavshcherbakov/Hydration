import Foundation
import HydrationDomain

public enum DrinkChangeMessageError: Error, Equatable {
    case unsupportedVersion(Int?)
    case malformedIdentifier(String?)
    case amountOutOfRange(Int?)
    case missingDay
    case missingTimestamp
}

public enum DrinkChangeMessageMapper {
    public static func message(forLogging entry: DrinkEntry) -> DrinkChangeMessage {
        DrinkChangeMessage(
            id: entry.id.uuidString,
            amountML: entry.volume.milliliters,
            day: entry.day.timeIntervalSince1970,
            recordedAt: entry.recordedAt.timeIntervalSince1970,
            deleted: false,
            version: DrinkChangeMessage.currentVersion
        )
    }

    public static func message(forRemoving id: UUID) -> DrinkChangeMessage {
        DrinkChangeMessage(
            id: id.uuidString,
            amountML: nil,
            day: nil,
            recordedAt: nil,
            deleted: true,
            version: DrinkChangeMessage.currentVersion
        )
    }

    public static func change(from message: DrinkChangeMessage) throws -> DrinkChange {
        guard let version = message.version, version <= DrinkChangeMessage.currentVersion else {
            throw DrinkChangeMessageError.unsupportedVersion(message.version)
        }
        guard let raw = message.id, let id = UUID(uuidString: raw) else {
            throw DrinkChangeMessageError.malformedIdentifier(message.id)
        }

        if message.deleted == true {
            return .removed(id)
        }

        return .logged(try entry(from: message, id: id))
    }

    private static func entry(from message: DrinkChangeMessage, id: UUID) throws -> DrinkEntry {
        guard let amount = message.amountML,
              let volume = Volume(milliliters: amount), volume > .zero else {
            throw DrinkChangeMessageError.amountOutOfRange(message.amountML)
        }
        guard let day = message.day else {
            throw DrinkChangeMessageError.missingDay
        }
        guard let recordedAt = message.recordedAt else {
            throw DrinkChangeMessageError.missingTimestamp
        }

        return DrinkEntry(
            id: id,
            volume: volume,
            day: Date(timeIntervalSince1970: day),
            recordedAt: Date(timeIntervalSince1970: recordedAt)
        )
    }
}
