import Foundation
import HydrationDomain

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

    public static func change(from message: DrinkChangeMessage) -> DrinkChange? {
        guard let version = message.version, version <= DrinkChangeMessage.currentVersion else { return nil }
        guard let raw = message.id, let id = UUID(uuidString: raw) else { return nil }

        if message.deleted == true {
            return .removed(id)
        }

        guard let amount = message.amountML,
              let volume = Volume(milliliters: amount), volume > .zero,
              let day = message.day,
              let recordedAt = message.recordedAt else {
            return nil
        }

        return .logged(
            DrinkEntry(
                id: id,
                volume: volume,
                day: Date(timeIntervalSince1970: day),
                recordedAt: Date(timeIntervalSince1970: recordedAt)
            )
        )
    }
}
