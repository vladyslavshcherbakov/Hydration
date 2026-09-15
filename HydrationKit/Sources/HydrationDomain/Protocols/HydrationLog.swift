public enum LogLevel: String, Sendable {
    case info
    case warning
    case error
}

public protocol HydrationLog: Sendable {
    func write(_ level: LogLevel, _ message: String)
}
