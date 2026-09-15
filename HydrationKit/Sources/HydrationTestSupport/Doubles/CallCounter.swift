import Foundation

public final class CallCounter: @unchecked Sendable {
    private var value = 0
    private let lock = NSLock()

    // MARK: - Public

    public init() {}

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
