import Foundation

public enum PairedDeviceMessageError: Error, Equatable {
    case unsupportedKind(String)
}

public enum PairedDeviceMessage: Equatable, Sendable {
    case change(DrinkChangeMessage)
    case daySnapshot(DaySnapshotMessage)

    private enum Kind: String {
        case change
        case daySnapshot
    }

    private static let kindKey = "kind"

    public init(dictionary: [String: Any]) throws {
        guard let raw = dictionary[Self.kindKey] as? String else {
            self = .change(DrinkChangeMessage(dictionary: dictionary))
            return
        }
        guard let kind = Kind(rawValue: raw) else {
            throw PairedDeviceMessageError.unsupportedKind(raw)
        }

        switch kind {
        case .change: self = .change(DrinkChangeMessage(dictionary: dictionary))
        case .daySnapshot: self = .daySnapshot(DaySnapshotMessage(dictionary: dictionary))
        }
    }

    public var dictionary: [String: Any] {
        var values = payload
        values[Self.kindKey] = kind.rawValue
        return values
    }

    private var kind: Kind {
        switch self {
        case .change: return .change
        case .daySnapshot: return .daySnapshot
        }
    }

    private var payload: [String: Any] {
        switch self {
        case .change(let message): return message.dictionary
        case .daySnapshot(let message): return message.dictionary
        }
    }
}

extension PairedDeviceMessage: CustomStringConvertible {
    public var description: String {
        switch self {
        case .change(let message): return "a change \(message.dictionary)"
        case .daySnapshot(let message): return "the picture of a day holding \(message.drinks.count) drinks"
        }
    }
}
