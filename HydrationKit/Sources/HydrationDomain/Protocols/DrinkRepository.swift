import Foundation

public protocol DrinkRepository: Sendable {
    func entries(in range: DateInterval) async throws -> [DrinkEntry]
    func save(_ entry: DrinkEntry) async throws
    func delete(id: UUID) async throws
}

extension DrinkRepository {
    public func entries(of day: Date, in calendar: Calendar) async throws -> [DrinkEntry] {
        let nextDay = calendar.date(byAdding: .day, value: 1, to: day) ?? day.addingTimeInterval(86_400)
        return try await entries(in: DateInterval(start: day, end: nextDay))
    }
}
