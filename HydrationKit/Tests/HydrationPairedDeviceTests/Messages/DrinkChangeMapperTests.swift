import Foundation
import HydrationDomain
import XCTest
@testable import HydrationPairedDevice

final class DrinkChangeMapperTests: XCTestCase {

    // MARK: - Tests

    func test_entry_whenTheAmountIsValid_carriesEveryField() throws {
        let id = UUID()
        let day = Date(timeIntervalSince1970: 1_700_000_000)
        let recordedAt = Date(timeIntervalSince1970: 1_700_032_000)

        let entry = try DrinkChangeMapper.entry(
            from: DrinkMessage(id: id, amountML: 450, day: day, recordedAt: recordedAt)
        )

        XCTAssertEqual(entry.id, id)
        XCTAssertEqual(entry.volume.milliliters, 450)
        XCTAssertEqual(entry.day, day)
        XCTAssertEqual(entry.recordedAt, recordedAt)
    }

    func test_entry_whenTheAmountIsZero_isRefused() {
        assertRefuses(amountML: 0)
    }

    func test_entry_whenTheAmountIsNegative_isRefused() {
        assertRefuses(amountML: -250)
    }

    func test_entry_whenTheAmountIsAboveTheSafetyLimit_isRefused() {
        assertRefuses(amountML: 6001)
    }

    func test_message_whenADrinkIsLogged_carriesItsAmountInMillilitres() throws {
        let entry = DrinkEntry(
            id: UUID(),
            volume: try XCTUnwrap(Volume(milliliters: 350)),
            day: Date(),
            recordedAt: Date()
        )

        guard case .drinkLogged(let drink) = DrinkChangeMapper.message(forLogging: entry).content else {
            return XCTFail("expected a logged drink")
        }
        XCTAssertEqual(drink.amountML, 350)
    }

    func test_message_whenADrinkIsRemoved_carriesOnlyItsIdentifier() {
        let id = UUID()

        guard case .drinkRemoved(let removal) = DrinkChangeMapper.message(forRemoving: id).content else {
            return XCTFail("expected a removal")
        }
        XCTAssertEqual(removal.id, id)
    }

    func test_message_whenADayIsSent_carriesTheDayAndEveryDrinkInIt() throws {
        let day = Date(timeIntervalSince1970: 1_700_000_000)
        let drinks = [
            DrinkEntry(id: UUID(), volume: try XCTUnwrap(Volume(milliliters: 250)), day: day, recordedAt: day),
            DrinkEntry(id: UUID(), volume: try XCTUnwrap(Volume(milliliters: 500)), day: day, recordedAt: day)
        ]

        guard case .daySnapshot(let snapshot) = DrinkChangeMapper.message(forDay: day, drinks: drinks).content else {
            return XCTFail("expected a day")
        }
        XCTAssertEqual(snapshot.day, day)
        XCTAssertEqual(snapshot.drinks.map(\.amountML), [250, 500])
    }

    // MARK: - Helpers

    private func assertRefuses(amountML: Int, file: StaticString = #filePath, line: UInt = #line) {
        let message = DrinkMessage(id: UUID(), amountML: amountML, day: Date(), recordedAt: Date())

        XCTAssertThrowsError(try DrinkChangeMapper.entry(from: message), file: file, line: line) { error in
            XCTAssertEqual(error as? DrinkMappingError, .amountOutOfRange(amountML), file: file, line: line)
        }
    }
}
