import Foundation
import HydrationDomain

public final class FailingDrinkRepository: DrinkRepository, LocalDrinkWriter {
    private let error: HydrationError

    // MARK: - Public

    public init(error: HydrationError = .storageUnavailable) {
        self.error = error
    }

    public func entries(in range: DateInterval) async throws -> [DrinkEntry] {
        throw error
    }

    public func save(_ entry: DrinkEntry) async throws {
        throw error
    }

    public func delete(id: UUID) async throws {
        throw error
    }

    public func replaceEntries(in range: DateInterval, with entries: [DrinkEntry]) async throws {
        throw error
    }
}
