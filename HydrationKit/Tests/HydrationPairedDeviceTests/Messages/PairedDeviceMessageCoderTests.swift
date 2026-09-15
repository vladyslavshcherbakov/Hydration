import Foundation
import XCTest
@testable import HydrationPairedDevice

final class PairedDeviceMessageCoderTests: XCTestCase {

    // MARK: - Tests

    func test_loggedDrink_whenEncodedAndRead_comesBackWhole() throws {
        let drink = DrinkMessage(
            id: UUID(),
            amountML: 450,
            day: Date(timeIntervalSince1970: 1_700_000_000),
            recordedAt: Date(timeIntervalSince1970: 1_700_032_000)
        )

        let decoded = try PairedDeviceMessageCoder.decode(
            try PairedDeviceMessageCoder.encode(PairedDeviceMessage(content: .drinkLogged(drink)))
        )

        XCTAssertEqual(decoded.content, .drinkLogged(drink))
    }

    func test_removal_whenEncodedAndRead_comesBackWhole() throws {
        let removal = DrinkRemovalMessage(id: UUID())

        let decoded = try PairedDeviceMessageCoder.decode(
            try PairedDeviceMessageCoder.encode(PairedDeviceMessage(content: .drinkRemoved(removal)))
        )

        XCTAssertEqual(decoded.content, .drinkRemoved(removal))
    }

    func test_dayOfDrinks_whenEncodedAndRead_comesBackWhole() throws {
        let day = DayOfDrinksMessage(
            day: Date(timeIntervalSince1970: 1_700_000_000),
            drinks: [
                DrinkMessage(id: UUID(), amountML: 250, day: Date(), recordedAt: Date()),
                DrinkMessage(id: UUID(), amountML: 500, day: Date(), recordedAt: Date())
            ]
        )

        let decoded = try PairedDeviceMessageCoder.decode(
            try PairedDeviceMessageCoder.encode(PairedDeviceMessage(content: .daySnapshot(day)))
        )

        guard case .daySnapshot(let read) = decoded.content else { return XCTFail("expected a day") }
        XCTAssertEqual(read.drinks.count, 2)
    }

    func test_message_whenItComesFromANewerBuild_isRefusedByVersion() throws {
        let newer = PairedDeviceMessage(
            version: PairedDeviceMessage.currentVersion + 1,
            content: .drinkRemoved(DrinkRemovalMessage(id: UUID()))
        )
        let payload = try PairedDeviceMessageCoder.encode(newer)

        XCTAssertThrowsError(try PairedDeviceMessageCoder.decode(payload)) { error in
            XCTAssertEqual(
                error as? PairedDeviceMessageError,
                .unsupportedVersion(PairedDeviceMessage.currentVersion + 1)
            )
        }
    }

    func test_message_whenTheBytesAreNotAMessage_isRefused() {
        XCTAssertThrowsError(try PairedDeviceMessageCoder.decode(Data("not a message".utf8)))
    }

    func test_message_whenTheBytesAreEmpty_isRefused() {
        XCTAssertThrowsError(try PairedDeviceMessageCoder.decode(Data()))
    }
}
