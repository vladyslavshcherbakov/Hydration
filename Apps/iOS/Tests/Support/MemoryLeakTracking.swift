import XCTest

extension XCTestCase {
    func assertNothingHolds(_ instance: AnyObject, file: StaticString = #filePath, line: UInt = #line) {
        addTeardownBlock { [weak instance] in
            XCTAssertNil(instance, "the test ended while something still held this object", file: file, line: line)
        }
    }
}
