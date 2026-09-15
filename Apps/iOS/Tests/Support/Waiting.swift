import Foundation
import XCTest

extension XCTestCase {
    func waitFor(
        _ condition: () throws -> Bool,
        within attempts: Int = 200,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async throws {
        for _ in 0..<attempts {
            if (try? condition()) == true { return }
            try await Task.sleep(nanoseconds: 10_000_000)
        }
        XCTFail("the screen never reached the expected state", file: file, line: line)
    }
}
