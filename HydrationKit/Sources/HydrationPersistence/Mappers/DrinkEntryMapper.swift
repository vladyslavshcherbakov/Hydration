import CoreData
import HydrationDomain

enum MappingError: Error, Equatable {
    case missingIdentifier
    case missingDay
    case missingTimestamp
    case invalidAmount(Int64)
    case unsupportedSchema(Int16)
}

// MARK: - DrinkEntryMapper

enum DrinkEntryMapper {
    static let supportedSchemaVersion: Int16 = 1

    static func toDTO(_ managedEntry: CDDrinkEntry) -> DrinkEntryDTO {
        DrinkEntryDTO(
            id: managedEntry.id,
            amountML: managedEntry.amountML,
            day: managedEntry.day,
            recordedAt: managedEntry.recordedAt,
            schemaVersion: managedEntry.schemaVersion
        )
    }

    static func toDTO(_ entry: DrinkEntry) -> DrinkEntryDTO {
        DrinkEntryDTO(
            id: entry.id,
            amountML: Int64(entry.volume.milliliters),
            day: entry.day,
            recordedAt: entry.recordedAt,
            schemaVersion: supportedSchemaVersion
        )
    }

    static func toDomain(_ dto: DrinkEntryDTO) throws -> DrinkEntry {
        guard dto.schemaVersion <= supportedSchemaVersion else {
            throw MappingError.unsupportedSchema(dto.schemaVersion)
        }
        guard let id = dto.id else {
            throw MappingError.missingIdentifier
        }
        guard let day = dto.day else {
            throw MappingError.missingDay
        }
        guard let recordedAt = dto.recordedAt else {
            throw MappingError.missingTimestamp
        }
        guard dto.amountML > 0, dto.amountML <= Int64(Int.max),
              let volume = Volume(milliliters: Int(dto.amountML)) else {
            throw MappingError.invalidAmount(dto.amountML)
        }
        return DrinkEntry(id: id, volume: volume, day: day, recordedAt: recordedAt)
    }

    static func apply(_ dto: DrinkEntryDTO, to managedEntry: CDDrinkEntry) {
        managedEntry.id = dto.id
        managedEntry.amountML = dto.amountML
        managedEntry.day = dto.day
        managedEntry.recordedAt = dto.recordedAt
        managedEntry.schemaVersion = dto.schemaVersion
    }
}
