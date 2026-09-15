import XCTest

final class EverydayUseUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        launch(resettingStore: true)
    }

    override func tearDown() {
        app = nil
        super.tearDown()
    }

    // MARK: - Tests
    func test_quickAdd_whenTappedTwice_showsHalfALitre() {
        XCTAssertTrue(total.waitForExistence(timeout: 5))
        XCTAssertEqual(total.label, "0 L")

        quickAdd.tap()
        quickAdd.tap()

        XCTAssertTrue(total.waitForLabel("0.5 L", timeout: 5))
    }

    func test_usersDays_whenTheUserLooksForThem_areOnScreen() {
        quickAdd.tap()

        let historyButton = app.buttons["today.history"]
        if historyButton.waitForExistence(timeout: 2) {
            historyButton.tap()
        }

        XCTAssertTrue(element("history.list").waitForExistence(timeout: 5))
        XCTAssertTrue(historyRow(daysAgo: 0).exists)
    }

    func test_todayScreen_whenTheAppIsReopened_stillShowsTheWater() {
        quickAdd.tap()
        XCTAssertTrue(total.waitForLabel("0.25 L", timeout: 5))

        app.terminate()
        launch(resettingStore: false)

        XCTAssertTrue(total.waitForExistence(timeout: 5))
        XCTAssertTrue(total.waitForLabel("0.25 L", timeout: 5))
    }

    func test_loggedDrink_whenSwipedAway_leavesTheTotal() {
        quickAdd.tap()
        XCTAssertTrue(total.waitForLabel("0.25 L", timeout: 5))

        let drink = app.cells.containing(.staticText, identifier: "250 ml").element
        drink.swipeLeft()
        app.buttons["Remove"].tap()

        XCTAssertTrue(total.waitForLabel("0 L", timeout: 5))
    }

    // MARK: - Helpers
    private func launch(resettingStore: Bool) {
        var arguments = ["-uiTestStore", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        if resettingStore {
            arguments.append("-resetStore")
        }
        app.launchArguments = arguments
        app.launch()
    }

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
}

// MARK: - XCUIElement
private extension XCUIElement {
    func waitForLabel(_ expected: String, timeout: TimeInterval) -> Bool {
        let predicate = NSPredicate(format: "label == %@", expected)
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: self)
        return XCTWaiter().wait(for: [expectation], timeout: timeout) == .completed
    }
}
