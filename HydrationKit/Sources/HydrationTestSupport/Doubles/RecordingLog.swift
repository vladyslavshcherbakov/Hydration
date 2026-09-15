import Foundation
import HydrationDomain

public final class RecordingLog: HydrationLog, @unchecked Sendable {
    private var lines: [String] = []
    private let lock = NSLock()

    public init() {}

    public var written: [String] {
        lock.lock()
        defer { lock.unlock() }
        return lines
    }

    public func write(_ level: LogLevel, _ message: String) {
        lock.lock()
        lines.append("[\(level.rawValue)] \(message)")
        lock.unlock()
    }
}
