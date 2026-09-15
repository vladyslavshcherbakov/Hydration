import Foundation

public struct CurrentDay: Sendable {
    private let dateProvider: DateProvider
    private let calendar: Calendar

    public init(dateProvider: DateProvider, calendar: Calendar) {
        self.dateProvider = dateProvider
        self.calendar = calendar
    }

    public func start() -> Date {
        calendar.dayInterval(for: dateProvider.now()).start
    }
}
