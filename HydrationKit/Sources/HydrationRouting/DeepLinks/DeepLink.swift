import Foundation
import HydrationDomain

public enum DeepLink: Equatable, Hashable, Sendable {
    case today
    case history
    case addDrink(milliliters: Int)
}

public enum DeepLinkOutcome: Equatable, Sendable {
    case handled
    case rejected(HydrationError)
}
