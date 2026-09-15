import Foundation
import HydrationDomain

struct ConsoleLog: HydrationLog {
    private let category: String

    init(category: String) {
        self.category = category
    }

    func write(_ level: LogLevel, _ message: String) {
        print("\(timestamp()) [\(level.rawValue)] \(category): \(message)")
    }

    private func timestamp() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "MMM d HH:mm:ss.SSS"
        return formatter.string(from: Date())
    }
}
