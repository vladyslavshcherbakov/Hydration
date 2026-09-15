import Foundation

public struct HydrationGoal: Equatable, Hashable, Sendable {
    public static let standard = HydrationGoal(target: Volume(milliliters: 2500)!)

    public let target: Volume

    public init(target: Volume) {
        self.target = target
    }
}

// MARK: - HydrationStatus
public enum HydrationStatus: Equatable, Hashable, Sendable {
    case behind
    case onTrack
    case reached
    case excessive
}
