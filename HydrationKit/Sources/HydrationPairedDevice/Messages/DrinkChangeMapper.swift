import Foundation
import HydrationDomain

public enum DrinkMappingError: Error, Equatable {
    case amountOutOfRange(Int)
}

public enum DrinkChangeMapper {
    public static func message(forLogging entry: DrinkEntry) -> PairedDeviceMessage {
        PairedDeviceMessage(content: .drinkLogged(drinkMessage(for: entry)))
    }

    public static func message(forRemoving id: UUID) -> PairedDeviceMessage {
        PairedDeviceMessage(content: .drinkRemoved(DrinkRemovalMessage(id: id)))
    }

    public static func message(forDay day: Date, drinks: [DrinkEntry]) -> PairedDeviceMessage {
        PairedDeviceMessage(
            content: .daySnapshot(DayOfDrinksMessage(day: day, drinks: drinks.map(drinkMessage(for:))))
        )
    }

    public static func entry(from message: DrinkMessage) throws -> DrinkEntry {
        guard let volume = Volume(milliliters: message.amountML), volume > .zero else {
            throw DrinkMappingError.amountOutOfRange(message.amountML)
        }

        return DrinkEntry(id: message.id, volume: volume, day: message.day, recordedAt: message.recordedAt)
    }

    private static func drinkMessage(for entry: DrinkEntry) -> DrinkMessage {
        DrinkMessage(
            id: entry.id,
            amountML: entry.volume.milliliters,
            day: entry.day,
            recordedAt: entry.recordedAt
        )
    }
}
