#if os(iOS)
import Foundation
import HydrationDomain

public final class WidgetRefreshingDrinkRepository: DrinkRepository, LocalDrinkWriter {
    private let localStorage: DrinkRepository & LocalDrinkWriter
    private let onWrite: @Sendable () async -> Void

    public init(localStorage: DrinkRepository & LocalDrinkWriter, onWrite: @escaping @Sendable () async -> Void) {
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

    public func replaceEntries(in range: DateInterval, with entries: [DrinkEntry]) async throws {
        try await localStorage.replaceEntries(in: range, with: entries)
        await onWrite()
    }
}
#endif
