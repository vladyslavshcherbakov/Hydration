import Foundation
import HydrationDomain

public final class InMemoryDrinkRepository: DrinkRepository, LocalDrinkWriter, @unchecked Sendable {
    private var entries: [UUID: DrinkEntry] = [:]
    private let lock = NSLock()

    // MARK: - Public

    public init(_ entries: [DrinkEntry] = []) {
        self.entries = Dictionary(uniqueKeysWithValues: entries.map { ($0.id, $0) })
    }

    public var stored: [DrinkEntry] {
        lock.lock()
        defer { lock.unlock() }
        return entries.values.sorted { $0.recordedAt < $1.recordedAt }
    }

    public func entries(in range: DateInterval) async throws -> [DrinkEntry] {
        stored.filter { range.contains($0.day) }
    }

    public func save(_ entry: DrinkEntry) async throws {
        put(entry)
    }

    public func delete(id: UUID) async throws {
        remove(id)
    }

    public func replaceEntries(in range: DateInterval, with arriving: [DrinkEntry]) async throws {
        replace(range, with: arriving)
    }

    // MARK: - Private

    private func put(_ entry: DrinkEntry) {
        lock.lock()
        entries[entry.id] = entry
        lock.unlock()
    }

    private func remove(_ id: UUID) {
        lock.lock()
        entries[id] = nil
        lock.unlock()
    }

    private func replace(_ range: DateInterval, with arriving: [DrinkEntry]) {
        lock.lock()
        for entry in entries.values where range.contains(entry.day) {
            entries[entry.id] = nil
        }
        for entry in arriving {
            entries[entry.id] = entry
        }
        lock.unlock()
    }
}
