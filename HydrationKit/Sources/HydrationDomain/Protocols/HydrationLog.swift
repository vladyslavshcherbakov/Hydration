public enum LogLevel: String, Sendable {
    case info
    case warning
    case error
}

// MARK: - HydrationLog

public protocol HydrationLog: Sendable {
    func write(_ level: LogLevel, _ message: String)
}
