import HydrationDesignSystem
import HydrationDomain
import XCTest

final class SemanticColorTests: XCTestCase {

    // MARK: - Tests

    func test_token_whenTheDayIsBehindSchedule_warns() {
        XCTAssertEqual(SemanticColor(status: .behind), .warning)
    }

    func test_token_whenTheDayIsOnTrack_isNeutral() {
        XCTAssertEqual(SemanticColor(status: .onTrack), .neutral)
    }

    func test_token_whenTheGoalIsReached_isPositive() {
        XCTAssertEqual(SemanticColor(status: .reached), .positive)
    }

    func test_token_whenTheDayIsExcessive_isCritical() {
        XCTAssertEqual(SemanticColor(status: .excessive), .critical)
    }

    func test_tokens_whenTakenTogether_areFourDistinctOnes() {
        let tokens: Set<SemanticColor> = [
            SemanticColor(status: .behind),
            SemanticColor(status: .onTrack),
            SemanticColor(status: .reached),
            SemanticColor(status: .excessive)
        ]

        XCTAssertEqual(tokens.count, 4)
    }
}
