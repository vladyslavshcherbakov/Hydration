import Foundation

public protocol LocalDrinkWriter: Sendable {
    func save(_ entry: DrinkEntry) async throws
    func delete(id: UUID) async throws
}
