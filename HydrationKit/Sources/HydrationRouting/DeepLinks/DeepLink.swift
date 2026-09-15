import Foundation
import HydrationDomain

public enum DeepLink: Equatable, Hashable, Sendable {
    case today
    case history
    case addDrink(milliliters: Int)
}

// MARK: - DeepLinkOutcome

public enum DeepLinkOutcome: Equatable, Sendable {
    case handled
    case rejected(HydrationError)
}
