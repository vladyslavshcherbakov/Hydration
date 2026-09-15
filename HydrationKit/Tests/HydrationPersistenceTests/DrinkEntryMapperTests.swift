import Foundation
import HydrationDomain
import XCTest
@testable import HydrationPersistence

final class DrinkEntryMapperTests: XCTestCase {

    // MARK: - Tests

    func test_row_whenEveryFieldIsThere_becomesADrink() throws {
        let id = UUID()
        let day = Date(timeIntervalSince1970: 1_700_000_000)
        let recordedAt = Date(timeIntervalSince1970: 1_700_032_000)

        let entry = try DrinkEntryMapper.toDomain(row(id: id, amountML: 450, day: day, recordedAt: recordedAt))

        XCTAssertEqual(entry.id, id)
        XCTAssertEqual(entry.volume.milliliters, 450)
        XCTAssertEqual(entry.day, day)
        XCTAssertEqual(entry.recordedAt, recordedAt)
    }

    func test_row_whenItComesFromANewerSchema_isRefused() {
        assertRefuses(
            row(schemaVersion: DrinkEntryMapper.supportedSchemaVersion + 1),
            with: .unsupportedSchema(DrinkEntryMapper.supportedSchemaVersion + 1)
        )
    }

    func test_row_whenItHasNoIdentifier_isRefused() {
        assertRefuses(row(id: nil), with: .missingIdentifier)
    }

    func test_row_whenItHasNoDay_isRefused() {
        assertRefuses(row(day: nil), with: .missingDay)
    }

    func test_row_whenItHasNoTimestamp_isRefused() {
        assertRefuses(row(recordedAt: nil), with: .missingTimestamp)
    }

    func test_row_whenItsAmountIsZero_isRefused() {
        assertRefuses(row(amountML: 0), with: .invalidAmount(0))
    }

    func test_row_whenItsAmountIsNegative_isRefused() {
        assertRefuses(row(amountML: -50), with: .invalidAmount(-50))
    }

    func test_row_whenItsAmountIsAboveTheSafetyLimit_isRefused() {
        assertRefuses(row(amountML: 7000), with: .invalidAmount(7000))
    }

    func test_drink_whenWrittenAsARow_carriesTheSupportedSchema() throws {
        let entry = DrinkEntry(
            id: UUID(),
            volume: try XCTUnwrap(Volume(milliliters: 350)),
            day: Date(timeIntervalSince1970: 1_700_000_000),
            recordedAt: Date(timeIntervalSince1970: 1_700_032_000)
        )

        let dto = DrinkEntryMapper.toDTO(entry)

        XCTAssertEqual(dto.schemaVersion, DrinkEntryMapper.supportedSchemaVersion)
        XCTAssertEqual(dto.amountML, 350)
        XCTAssertEqual(dto.id, entry.id)
    }

    // MARK: - Helpers

    private func row(
        id: UUID? = UUID(),
        amountML: Int64 = 250,
        day: Date? = Date(timeIntervalSince1970: 1_700_000_000),
        recordedAt: Date? = Date(timeIntervalSince1970: 1_700_032_000),
        schemaVersion: Int16 = DrinkEntryMapper.supportedSchemaVersion
    ) -> DrinkEntryDTO {
        DrinkEntryDTO(id: id, amountML: amountML, day: day, recordedAt: recordedAt, schemaVersion: schemaVersion)
    }

    private func assertRefuses(
        _ dto: DrinkEntryDTO,
        with expected: MappingError,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertThrowsError(try DrinkEntryMapper.toDomain(dto), file: file, line: line) { error in
            XCTAssertEqual(error as? MappingError, expected, file: file, line: line)
        }
    }
}
