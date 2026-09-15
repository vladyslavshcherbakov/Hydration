import Foundation
import HydrationDomain
import HydrationRouting
import XCTest

final class DeepLinkMapperTests: XCTestCase {

    // MARK: - Tests

    func test_today_whenWrittenAndReadBack_isTheSameLink() {
        assertRoundTrip(.today)
    }

    func test_history_whenWrittenAndReadBack_isTheSameLink() {
        assertRoundTrip(.history)
    }

    func test_addDrink_whenWrittenAndReadBack_keepsTheAmount() {
        assertRoundTrip(.addDrink(milliliters: 250))
    }

    func test_link_whenTheSchemeBelongsToSomeoneElse_isNotOurs() {
        XCTAssertNil(DeepLinkMapper.link(from: URL(string: "https://history")!))
    }

    func test_link_whenTheHostIsUnknown_isNotOurs() {
        XCTAssertNil(DeepLinkMapper.link(from: URL(string: "hydration://settings")!))
    }

    func test_link_whenThereIsNoHost_isNotOurs() {
        XCTAssertNil(DeepLinkMapper.link(from: URL(string: "hydration://")!))
    }

    func test_addDrink_whenTheAmountIsMissing_isRefused() {
        XCTAssertNil(DeepLinkMapper.link(from: URL(string: "hydration://add")!))
    }

    func test_addDrink_whenTheAmountIsNotANumber_isRefused() {
        XCTAssertNil(DeepLinkMapper.link(from: URL(string: "hydration://add?ml=lots")!))
    }

    func test_addDrink_whenTheAmountIsZero_isRefused() {
        XCTAssertNil(DeepLinkMapper.link(from: URL(string: "hydration://add?ml=0")!))
    }

    func test_addDrink_whenTheAmountIsNegative_isRefused() {
        XCTAssertNil(DeepLinkMapper.link(from: URL(string: "hydration://add?ml=-250")!))
    }

    func test_addDrink_whenTheAmountIsAboveTheSafetyLimit_isRefused() {
        XCTAssertNil(DeepLinkMapper.link(from: URL(string: "hydration://add?ml=6001")!))
    }

    func test_addDrink_whenTheAmountIsExactlyTheSafetyLimit_isAccepted() {
        XCTAssertEqual(
            DeepLinkMapper.link(from: URL(string: "hydration://add?ml=6000")!),
            .addDrink(milliliters: 6000)
        )
    }

    func test_addDrink_whenOtherQueryItemsRideAlong_stillReadsTheAmount() {
        XCTAssertEqual(
            DeepLinkMapper.link(from: URL(string: "hydration://add?source=widget&ml=250")!),
            .addDrink(milliliters: 250)
        )
    }

    // MARK: - Helpers

    private func assertRoundTrip(_ link: DeepLink, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(DeepLinkMapper.link(from: DeepLinkMapper.url(for: link)), link, file: file, line: line)
    }
}
