import XCTest

final class UsingTheAppOnAWideScreenUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-uiTestStore", "-resetStore", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()
    }

    override func tearDown() {
        app = nil
        super.tearDown()
    }

    // MARK: - Tests

    func test_usersDays_whenTheScreenIsWide_areOnScreenWithoutBeingAskedFor() throws {
        try skipUnlessTheScreenIsWide()

        XCTAssertTrue(historyList.exists)
        XCTAssertFalse(app.buttons["today.history"].exists)
    }

    func test_dayScreen_whenAnEarlierDayIsPickedInTheList_showsThatDay() throws {
        try skipUnlessTheScreenIsWide()
        quickAdd.tap()
        XCTAssertTrue(total.waitForLabel("0.25 L", timeout: 5))

        historyRow(daysAgo: 1).tap()

        XCTAssertTrue(total.waitForLabel("0 L", timeout: 5))
    }

    // MARK: - Helpers

    private var historyList: XCUIElement { element("history.list") }

    private func element(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }

    private func historyRow(daysAgo: Int) -> XCUIElement {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US_POSIX")
        let day = calendar.date(byAdding: .day, value: -daysAgo, to: Date())!
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return element("history.row.\(formatter.string(from: day))")
    }

    private var total: XCUIElement { app.staticTexts["today.total"] }

    private var quickAdd: XCUIElement { app.buttons["today.quickAdd"] }

    private func skipUnlessTheScreenIsWide() throws {
        let historyIsAlreadyOnScreen = historyList.waitForExistence(timeout: 5)
        try XCTSkipUnless(historyIsAlreadyOnScreen, "This screen shows one column at a time")
    }
}

// MARK: - XCUIElement

private extension XCUIElement {
    func waitForLabel(_ expected: String, timeout: TimeInterval) -> Bool {
        let matched = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "label == %@", expected),
            object: self
        )
        return XCTWaiter().wait(for: [matched], timeout: timeout) == .completed
    }
}
