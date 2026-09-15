import HydrationDesignSystem
import SwiftUI
import XCTest

final class HydrationAccentTests: XCTestCase {
    private let tokens: [SemanticColor] = [.neutral, .positive, .warning, .critical]

    // MARK: - Tests

    func test_colours_whenEveryTokenIsRendered_areFourDistinctOnes() {
        let colours = Set(tokens.map(HydrationAccent.color))

        XCTAssertEqual(colours.count, 4)
    }

    #if os(iOS)
    func test_uiColours_whenEveryTokenIsRendered_areFourDistinctOnes() {
        let colours = Set(tokens.map(HydrationAccent.uiColor))

        XCTAssertEqual(colours.count, 4)
    }

    func test_uiColour_whenRendered_isTheSameColourSwiftUIGets() {
        for token in tokens {
            XCTAssertEqual(HydrationAccent.color(token), Color(uiColor: HydrationAccent.uiColor(token)))
        }
    }

    func test_uiColours_whenRendered_areThePlatformSystemColours() {
        XCTAssertEqual(HydrationAccent.uiColor(.neutral), .systemBlue)
        XCTAssertEqual(HydrationAccent.uiColor(.positive), .systemGreen)
        XCTAssertEqual(HydrationAccent.uiColor(.warning), .systemOrange)
        XCTAssertEqual(HydrationAccent.uiColor(.critical), .systemRed)
    }
    #endif
}
