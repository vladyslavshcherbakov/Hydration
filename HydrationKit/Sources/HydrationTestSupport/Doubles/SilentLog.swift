import HydrationDomain

public struct SilentLog: HydrationLog {
    public init() {}

    public func write(_ level: LogLevel, _ message: String) {}
}
