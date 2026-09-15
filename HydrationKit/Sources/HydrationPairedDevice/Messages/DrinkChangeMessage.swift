import Foundation
import HydrationDomain

public struct DrinkChangeMessage: Equatable, Sendable {
    public static let currentVersion = 1

    public let id: String?
    public let amountML: Int?
    public let day: Double?
    public let recordedAt: Double?
    public let deleted: Bool?
    public let version: Int?

    public init(id: String?, amountML: Int?, day: Double?, recordedAt: Double?, deleted: Bool?, version: Int?) {
        self.id = id
        self.amountML = amountML
        self.day = day
        self.recordedAt = recordedAt
        self.deleted = deleted
        self.version = version
    }

    public var dictionary: [String: Any] {
        var values: [String: Any] = [:]
        values["id"] = id
        values["amountML"] = amountML
        values["day"] = day
        values["recordedAt"] = recordedAt
        values["deleted"] = deleted
        values["version"] = version
        return values
    }

    public init(dictionary: [String: Any]) {
        self.init(
            id: dictionary["id"] as? String,
            amountML: dictionary["amountML"] as? Int,
            day: dictionary["day"] as? Double,
            recordedAt: dictionary["recordedAt"] as? Double,
            deleted: dictionary["deleted"] as? Bool,
            version: dictionary["version"] as? Int
        )
    }
}

public enum DrinkChange: Equatable, Sendable {
    case logged(DrinkEntry)
    case removed(UUID)
}
