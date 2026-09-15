import Foundation
import HydrationDomain

public final class ObservedDrinkRepository: DrinkRepository, LocalDrinkWriter, DrinkChanges, @unchecked Sendable {
    private let localStorage: DrinkRepository & LocalDrinkWriter
    private let lock = NSLock()
    private var listeners: [UUID: AsyncStream<Void>.Continuation] = [:]

    // MARK: - Public

    public init(localStorage: DrinkRepository & LocalDrinkWriter) {
        self.localStorage = localStorage
    }

    public func entries(in range: DateInterval) async throws -> [DrinkEntry] {
        try await localStorage.entries(in: range)
    }

    public func save(_ entry: DrinkEntry) async throws {
        try await localStorage.save(entry)
        announce()
    }

    public func delete(id: UUID) async throws {
        try await localStorage.delete(id: id)
        announce()
    }

    public func replaceEntries(in range: DateInterval, with entries: [DrinkEntry]) async throws {
        try await localStorage.replaceEntries(in: range, with: entries)
        announce()
    }

    public func noteWrittenElsewhere() {
        announce()
    }

    public func whenDrinksChange() -> AsyncStream<Void> {
        AsyncStream { continuation in
            let listener = UUID()
            lock.lock()
            listeners[listener] = continuation
            lock.unlock()
            continuation.onTermination = { [weak self] _ in
                self?.forget(listener)
            }
        }
    }

    // MARK: - Private

    private func announce() {
        lock.lock()
        let listening = Array(listeners.values)
        lock.unlock()
        for continuation in listening {
            continuation.yield(())
        }
    }

    private func forget(_ listener: UUID) {
        lock.lock()
        listeners[listener] = nil
        lock.unlock()
    }
}
