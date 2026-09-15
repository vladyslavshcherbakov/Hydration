import Foundation
import HydrationDomain

public final class CallCounter: @unchecked Sendable {
    public init() {}

    private var value = 0
    private let lock = NSLock()

    public var count: Int {
        lock.lock()
        defer { lock.unlock() }
        return value
    }

    public func increment() {
        lock.lock()
        value += 1
        lock.unlock()
    }
}
