import Foundation

public struct DrinkMessage: Codable, Equatable, Sendable {
    public let id: UUID
    public let amountML: Int
    public let day: Date
    public let recordedAt: Date

    public init(id: UUID, amountML: Int, day: Date, recordedAt: Date) {
        self.id = id
        self.amountML = amountML
        self.day = day
        self.recordedAt = recordedAt
    }
}

// MARK: - DrinkRemovalMessage

public struct DrinkRemovalMessage: Codable, Equatable, Sendable {
    public let id: UUID

    public init(id: UUID) {
        self.id = id
    }
}

// MARK: - DayOfDrinksMessage

public struct DayOfDrinksMessage: Codable, Equatable, Sendable {
    public let day: Date
    public let drinks: [DrinkMessage]

    public init(day: Date, drinks: [DrinkMessage]) {
        self.day = day
        self.drinks = drinks
    }
}

// MARK: - PairedDeviceMessage

public struct PairedDeviceMessage: Codable, Equatable, Sendable {
    public static let currentVersion = 1

    // MARK: - Content

    public enum Content: Codable, Equatable, Sendable {
        case drinkLogged(DrinkMessage)
        case drinkRemoved(DrinkRemovalMessage)
        case daySnapshot(DayOfDrinksMessage)
    }

    public let version: Int
    public let content: Content

    public init(version: Int = PairedDeviceMessage.currentVersion, content: Content) {
        self.version = version
        self.content = content
    }
}

// MARK: - PairedDeviceMessage + CustomStringConvertible

extension PairedDeviceMessage: CustomStringConvertible {
    public var description: String {
        switch content {
        case .drinkLogged(let drink): return "a drink of \(drink.amountML) ml, \(drink.id)"
        case .drinkRemoved(let removal): return "a removal of the drink \(removal.id)"
        case .daySnapshot(let day): return "the picture of \(day.day) holding \(day.drinks.count) drinks"
        }
    }
}
