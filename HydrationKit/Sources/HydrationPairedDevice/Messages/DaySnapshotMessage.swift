import Foundation
import HydrationDomain

public struct DaySnapshotMessage: Equatable, Sendable {
    public static let currentVersion = 1

    public let day: Double?
    public let drinks: [DrinkChangeMessage]
    public let version: Int?

    public init(day: Double?, drinks: [DrinkChangeMessage], version: Int?) {
        self.day = day
        self.drinks = drinks
        self.version = version
    }

    public init(dictionary: [String: Any]) {
        self.init(
            day: dictionary["day"] as? Double,
            drinks: (dictionary["drinks"] as? [[String: Any]] ?? []).map(DrinkChangeMessage.init(dictionary:)),
            version: dictionary["version"] as? Int
        )
    }

    public var dictionary: [String: Any] {
        var values: [String: Any] = ["drinks": drinks.map(\.dictionary)]
        values["day"] = day
        values["version"] = version
        return values
    }
}

public struct DaySnapshot: Equatable, Sendable {
    public let day: Date
    public let drinks: [DrinkEntry]

    public init(day: Date, drinks: [DrinkEntry]) {
        self.day = day
        self.drinks = drinks
    }
}

public enum DaySnapshotMessageError: Error, Equatable {
    case unsupportedVersion(Int?)
    case missingDay
}

public enum DaySnapshotMessageMapper {
    public static func message(forDay day: Date, drinks: [DrinkEntry]) -> DaySnapshotMessage {
        DaySnapshotMessage(
            day: day.timeIntervalSince1970,
            drinks: drinks.map(DrinkChangeMessageMapper.message(forLogging:)),
            version: DaySnapshotMessage.currentVersion
        )
    }

    public static func snapshot(from message: DaySnapshotMessage) throws -> DaySnapshot {
        guard let version = message.version, version <= DaySnapshotMessage.currentVersion else {
            throw DaySnapshotMessageError.unsupportedVersion(message.version)
        }
        guard let day = message.day else {
            throw DaySnapshotMessageError.missingDay
        }

        return DaySnapshot(day: Date(timeIntervalSince1970: day), drinks: try drinks(of: message))
    }

    private static func drinks(of message: DaySnapshotMessage) throws -> [DrinkEntry] {
        try message.drinks.compactMap { drink in
            guard case .logged(let entry) = try DrinkChangeMessageMapper.change(from: drink) else { return nil }
            return entry
        }
    }
}
