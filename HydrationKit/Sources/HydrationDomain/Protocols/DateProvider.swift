import Foundation

public protocol DateProvider: Sendable {
    func now() -> Date
}

// MARK: - Calendar
extension Calendar {
    public func dayInterval(for date: Date) -> DateInterval {
        dateInterval(of: .day, for: date) ?? DateInterval(start: date, duration: 86_400)
    }
}
