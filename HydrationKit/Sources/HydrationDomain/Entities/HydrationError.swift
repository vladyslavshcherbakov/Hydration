import Foundation

public enum HydrationError: Error, Equatable {
    case invalidVolume
    case safetyLimitReached
    case nothingToRemove
    case storageUnavailable
}
