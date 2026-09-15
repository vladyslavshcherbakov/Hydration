#if canImport(WatchConnectivity)
import HydrationDomain
import HydrationTestSupport
import XCTest
@testable import HydrationPairedDevice

final class WatchConnectivityChannelTests: XCTestCase {
    private var session: RecordingPairedDeviceSession!

    override func setUp() {
        super.setUp()
        session = RecordingPairedDeviceSession()
    }

    override func tearDown() {
        session = nil
        super.tearDown()
    }

    // MARK: - Tests

    func test_channel_whenCreated_startsTheSession() {
        _ = makeChannel()

        XCTAssertTrue(session.started)
    }

    func test_send_whenThePairedDeviceIsReachable_sendsRatherThanQueues() {
        session.isReachable = true

        makeChannel().send(drinkMessage(250))

        XCTAssertEqual(session.sent.count, 1)
        XCTAssertTrue(session.queued.isEmpty)
    }

    func test_send_whenThePairedDeviceIsNotReachable_queuesRatherThanSends() {
        session.isReachable = false

        makeChannel().send(drinkMessage(250))

        XCTAssertEqual(session.queued.count, 1)
        XCTAssertTrue(session.sent.isEmpty)
    }

    func test_send_whenTheSendIsRefused_queuesTheSamePayload() throws {
        session.isReachable = true
        session.refuseSends = HydrationError.storageUnavailable

        makeChannel().send(drinkMessage(250))

        let sent = try XCTUnwrap(session.payload(of: try XCTUnwrap(session.sent.first)))
        let queued = try XCTUnwrap(session.payload(of: try XCTUnwrap(session.queued.first)))
        XCTAssertEqual(sent, queued)
    }

    func test_send_whenItLeaves_carriesTheEncodedMessage() throws {
        makeChannel().send(drinkMessage(450))

        let payload = try XCTUnwrap(session.payload(of: try XCTUnwrap(session.sent.first)))
        let decoded = try PairedDeviceMessageCoder.decode(payload)
        guard case .drinkLogged(let drink) = decoded.content else { return XCTFail("expected a logged drink") }
        XCTAssertEqual(drink.amountML, 450)
    }

    func test_arrivingMessage_whenSomethingIsListening_handsOverThePayload() {
        let channel = makeChannel()
        let arrived = expectation(description: "the payload reaches the receiver")
        channel.startReceiving { payload in
            XCTAssertFalse(payload.isEmpty)
            arrived.fulfill()
        }

        channel.deliver(["payload": Data("a message".utf8)], arrivedBy: "message")

        wait(for: [arrived], timeout: 1)
    }

    func test_arrivingMessage_whenItCarriesNoPayload_isDropped() {
        let channel = makeChannel()
        let arrived = expectation(description: "nothing reaches the receiver")
        arrived.isInverted = true
        channel.startReceiving { _ in arrived.fulfill() }

        channel.deliver(["something": "else"], arrivedBy: "message")

        wait(for: [arrived], timeout: 0.2)
    }

    func test_reachability_whenThePairedDeviceBecomesReachable_asksForTheResend() {
        session.isReachable = true
        let channel = makeChannel()
        let resent = expectation(description: "the resend is asked for")
        channel.whenPairedDeviceBecomesReachable { resent.fulfill() }

        channel.reachabilityChanged(describedAs: "the paired device changed")

        wait(for: [resent], timeout: 1)
    }

    func test_reachability_whenThePairedDeviceIsStillUnreachable_asksForNothing() {
        session.isReachable = false
        let channel = makeChannel()
        let resent = expectation(description: "no resend is asked for")
        resent.isInverted = true
        channel.whenPairedDeviceBecomesReachable { resent.fulfill() }

        channel.reachabilityChanged(describedAs: "the paired device changed")

        wait(for: [resent], timeout: 0.2)
    }

    // MARK: - Helpers

    private func makeChannel() -> WatchConnectivityChannel {
        WatchConnectivityChannel(session: session, log: SilentLog())
    }

    private func drinkMessage(_ milliliters: Int) -> PairedDeviceMessage {
        PairedDeviceMessage(
            content: .drinkLogged(
                DrinkMessage(id: UUID(), amountML: milliliters, day: Date(), recordedAt: Date())
            )
        )
    }
}
#endif
