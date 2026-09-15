import Foundation
import HydrationDomain


public final class MutableDateProvider: DateProvider, @unchecked Sendable {
    private var current: Date
    private let lock = NSLock()

    public init(now: Date) {
        current = now
    }

    public func now() -> Date {
        lock.lock()
        defer { lock.unlock() }
        return current
    }

    public func advance(by interval: TimeInterval) {
        lock.lock()
        current = current.addingTimeInterval(interval)
        lock.unlock()
    }

    public func set(_ date: Date) {
        lock.lock()
        current = date
        lock.unlock()
    }
}
