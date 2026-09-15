import XCTest

final class SharedStorageConfigurationTests: XCTestCase {
    func test_sharedContainer_whenTheAppAndTheWidgetAreBuilt_isTheSameForBoth() throws {
        let appGroup = try XCTUnwrap(Bundle.main.object(forInfoDictionaryKey: "AppGroupIdentifier") as? String)
        let widgetURL = Bundle.main.bundleURL.appendingPathComponent("PlugIns/HydrationWidget.appex")
        let widgetGroup = try XCTUnwrap(Bundle(url: widgetURL)?.object(forInfoDictionaryKey: "AppGroupIdentifier") as? String)

        XCTAssertEqual(appGroup, widgetGroup)
        XCTAssertNotNil(FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup))
    }
}
