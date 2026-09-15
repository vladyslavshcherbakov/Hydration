import HydrationDesignSystem
import SwiftUI
import XCTest

final class HydrationTypographyTests: XCTestCase {

    // MARK: - Tests

    func test_valueFont_whenTheSurfacesAreCompared_differsOnEachOfThem() {
        let values: Set<Font> = [
            HydrationTypography.phone.value,
            HydrationTypography.watch.value,
            HydrationTypography.widget.value
        ]

        XCTAssertEqual(values.count, 3)
    }

    func test_roles_whenTakenOnOneSurface_areNotAllTheSameFont() {
        let phone = HydrationTypography.phone

        XCTAssertNotEqual(phone.value, phone.caption)
        XCTAssertNotEqual(phone.status, phone.caption)
        XCTAssertNotEqual(phone.goal, phone.value)
    }

    func test_actionFont_whenTakenOnEverySurface_isTheSameOne() {
        XCTAssertEqual(HydrationTypography.phone.action, HydrationTypography.watch.action)
        XCTAssertEqual(HydrationTypography.watch.action, HydrationTypography.widget.action)
    }
}
