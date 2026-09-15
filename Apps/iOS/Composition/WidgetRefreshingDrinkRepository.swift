#if os(iOS)
import Foundation
import HydrationDomain

public final class WidgetRefreshingDrinkRepository: DrinkRepository, LocalDrinkWriter {
    private let localStorage: DrinkRepository
    private let onWrite: @Sendable () async -> Void

    public init(localStorage: DrinkRepository, onWrite: @escaping @Sendable () async -> Void) {
        self.localStorage = localStorage
        self.onWrite = onWrite
    }

    public func entries(in range: DateInterval) async throws -> [DrinkEntry] {
        try await localStorage.entries(in: range)
    }

    public func save(_ entry: DrinkEntry) async throws {
        try await localStorage.save(entry)
        await onWrite()
    }

    public func delete(id: UUID) async throws {
        try await localStorage.delete(id: id)
        await onWrite()
    }
}
#endif
