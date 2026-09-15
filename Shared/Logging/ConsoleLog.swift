import HydrationDomain

struct ConsoleLog: HydrationLog {
    private let category: String

    init(category: String) {
        self.category = category
    }

    func write(_ level: LogLevel, _ message: String) {
        print("[\(level.rawValue)] \(category): \(message)")
    }
}
