import Foundation

public enum DrinkChange: Equatable, Sendable {
    case onDay(Date)
    case onAnUnknownDay

    public func touches(_ period: DateInterval) -> Bool {
        switch self {
        case .onAnUnknownDay:
            return true
        case .onDay(let day):
            return period.contains(day)
        }
    }
}
