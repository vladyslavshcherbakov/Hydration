import Foundation
import HydrationDomain

public enum SemanticColor: Equatable, Hashable, Sendable {
    case neutral
    case positive
    case warning
    case critical

    public init(status: HydrationStatus) {
        switch status {
        case .behind: self = .warning
        case .onTrack: self = .neutral
        case .reached: self = .positive
        case .excessive: self = .critical
        }
    }
}
