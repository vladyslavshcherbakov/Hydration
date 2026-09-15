import Foundation

public struct Volume: Equatable, Hashable, Sendable, Comparable {
    public static let zero = Volume(unchecked: 0)
    public static let dailySafetyLimit = Volume(unchecked: 6000)
    public static let quickAdd = Volume(unchecked: 250)

    public let milliliters: Int

    private init(unchecked milliliters: Int) {
        self.milliliters = milliliters
    }

    public init?(milliliters: Int) {
        guard milliliters >= 0, milliliters <= Volume.dailySafetyLimit.milliliters else { return nil }
        self.milliliters = milliliters
    }

    public var liters: Double {
        Double(milliliters) / 1000.0
    }

    public static func < (lhs: Volume, rhs: Volume) -> Bool {
        lhs.milliliters < rhs.milliliters
    }

    public static func + (lhs: Volume, rhs: Volume) -> Volume {
        Volume(unchecked: min(lhs.milliliters + rhs.milliliters, Volume.dailySafetyLimit.milliliters))
    }

    public func subtracting(_ other: Volume) -> Volume {
        Volume(unchecked: max(0, milliliters - other.milliliters))
    }

    public func scaled(by factor: Double) -> Volume {
        let value = Int((Double(milliliters) * factor).rounded())
        return Volume(unchecked: max(0, min(value, Volume.dailySafetyLimit.milliliters)))
    }
}
