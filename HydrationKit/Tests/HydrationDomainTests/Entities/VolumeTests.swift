import HydrationDomain
import XCTest

final class VolumeTests: XCTestCase {

    // MARK: - Tests

    func test_volume_whenNegative_isRefused() {
        XCTAssertNil(Volume(milliliters: -1))
    }

    func test_volume_whenAboveTheDailySafetyLimit_isRefused() {
        XCTAssertNil(Volume(milliliters: 6001))
    }

    func test_volume_whenExactlyTheDailySafetyLimit_isAccepted() {
        XCTAssertEqual(Volume(milliliters: 6000), .dailySafetyLimit)
    }

    func test_volume_whenZero_isAccepted() {
        XCTAssertEqual(Volume(milliliters: 0), .zero)
    }

    func test_liters_whenSevenHundredAndFiftyMillilitres_isThreeQuarters() {
        XCTAssertEqual(Volume(milliliters: 750)?.liters, 0.75)
    }

    func test_sum_whenItWouldPassTheSafetyLimit_stopsAtTheLimit() throws {
        let almostFull = try XCTUnwrap(Volume(milliliters: 5900))
        let glass = try XCTUnwrap(Volume(milliliters: 500))

        XCTAssertEqual(almostFull + glass, .dailySafetyLimit)
    }

    func test_subtracting_whenTheOtherIsLarger_isZero() throws {
        let smaller = try XCTUnwrap(Volume(milliliters: 200))
        let larger = try XCTUnwrap(Volume(milliliters: 900))

        XCTAssertEqual(smaller.subtracting(larger), .zero)
    }

    func test_scaled_whenHalved_rounds() throws {
        let odd = try XCTUnwrap(Volume(milliliters: 333))

        XCTAssertEqual(odd.scaled(by: 0.5).milliliters, 167)
    }

    func test_scaled_whenItWouldPassTheSafetyLimit_stopsAtTheLimit() throws {
        let goal = try XCTUnwrap(Volume(milliliters: 5000))

        XCTAssertEqual(goal.scaled(by: 2), .dailySafetyLimit)
    }

    func test_scaled_whenTheFactorIsNegative_isZero() throws {
        let goal = try XCTUnwrap(Volume(milliliters: 1000))

        XCTAssertEqual(goal.scaled(by: -1), .zero)
    }

    func test_order_whenCompared_followsMillilitres() throws {
        let small = try XCTUnwrap(Volume(milliliters: 100))
        let large = try XCTUnwrap(Volume(milliliters: 900))

        XCTAssertLessThan(small, large)
    }
}
