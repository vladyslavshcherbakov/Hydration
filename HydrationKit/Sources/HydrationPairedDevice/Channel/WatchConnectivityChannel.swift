#if canImport(WatchConnectivity)
import Foundation
import HydrationDomain
import WatchConnectivity

public final class WatchConnectivityChannel: NSObject, PairedDeviceChannel, @unchecked Sendable {
    private static let payloadKey = "payload"

    private let session: PairedDeviceSession
    private let log: HydrationLog
    private let lock = NSLock()
    private var receive: ReceiveEncodedMessage?
    private var sendOnReachable: OnPairedDeviceReachable?

    // MARK: - Public

    public init(session: PairedDeviceSession, log: HydrationLog) {
        self.session = session
        self.log = log
        super.init()
        session.start(with: self)
    }

    public static func forThisDevice(log: HydrationLog) -> PairedDeviceChannel {
        guard WCSession.isSupported() else {
            log.write(.warning, "this device has no WatchConnectivity session, no change will reach a paired device")
            return NoPairedDeviceChannel()
        }
        return WatchConnectivityChannel(session: WCSession.default, log: log)
    }

    public func send(_ message: PairedDeviceMessage) {
        let payload: Data
        do {
            payload = try PairedDeviceMessageCoder.encode(message)
        } catch {
            log.write(.error, "\(message) could not be encoded for the paired device: \(error)")
            return
        }

        guard session.isReachable else {
            log.write(.info, "queueing \(message) for the paired device, it is not reachable, session is \(session.stateDescription)")
            session.queue(Self.userInfo(for: payload))
            return
        }

        log.write(.info, "sending \(message) to the paired device by message, session is \(session.stateDescription)")
        session.send(Self.userInfo(for: payload)) { [log, session] error in
            log.write(.warning, "the paired device did not take \(message) now, queueing it: \(error)")
            session.queue(Self.userInfo(for: payload))
        }
    }

    public func startReceiving(_ receive: @escaping ReceiveEncodedMessage) {
        lock.lock()
        self.receive = receive
        lock.unlock()
    }

    public func whenPairedDeviceBecomesReachable(_ send: @escaping OnPairedDeviceReachable) {
        lock.lock()
        self.sendOnReachable = send
        lock.unlock()
    }

    // MARK: - Internal

    func deliver(_ userInfo: [String: Any], arrivedBy delivery: String) {
        lock.lock()
        let receive = self.receive
        lock.unlock()
        guard let receive else {
            log.write(.warning, "a message arrived from the paired device before anything was listening: \(userInfo)")
            return
        }
        guard let payload = userInfo[Self.payloadKey] as? Data else {
            log.write(.warning, "a message arrived from the paired device with nothing in it: \(userInfo)")
            return
        }

        log.write(.info, "a message of \(payload.count) bytes arrived from the paired device by \(delivery)")
        Task { await receive(payload) }
    }

    func reachabilityChanged(describedAs description: String) {
        guard session.isReachable else {
            log.write(.info, "\(description) and it is not reachable, nothing is being sent to it, session is \(session.stateDescription)")
            return
        }

        log.write(.info, "\(description) and it is reachable, session is \(session.stateDescription)")
        pairedDeviceBecameReachable()
    }

    func queuedTransferFinished(error: Error?) {
        guard let error else {
            log.write(.info, "a queued transfer reached the paired device")
            return
        }
        log.write(.error, "a queued transfer never reached the paired device: \(error)")
    }

    func activationFinished(error: Error?) {
        if let error {
            log.write(.error, "the link to the paired device could not be activated: \(error)")
            return
        }
        log.write(.info, "the link to the paired device is ready, session is \(session.stateDescription)")
    }

    // MARK: - Private

    private static func userInfo(for payload: Data) -> [String: Any] {
        [payloadKey: payload]
    }

    private func pairedDeviceBecameReachable() {
        lock.lock()
        let send = self.sendOnReachable
        lock.unlock()
        guard let send else {
            log.write(.info, "the paired device became reachable and this app has nothing to send on reachability")
            return
        }
        Task { await send() }
    }
}

// MARK: - WatchConnectivityChannel + WCSessionDelegate

extension WatchConnectivityChannel: WCSessionDelegate {
    public func sessionReachabilityDidChange(_ session: WCSession) {
        reachabilityChanged(describedAs: "the paired device changed")
    }

    public func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        deliver(message, arrivedBy: "message")
    }

    public func session(
        _ session: WCSession,
        didReceiveMessage message: [String: Any],
        replyHandler: @escaping ([String: Any]) -> Void
    ) {
        deliver(message, arrivedBy: "message")
        replyHandler([:])
    }

    public func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
        deliver(userInfo, arrivedBy: "queued transfer")
    }

    public func session(_ session: WCSession, didFinish userInfoTransfer: WCSessionUserInfoTransfer, error: Error?) {
        queuedTransferFinished(error: error)
    }

    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        activationFinished(error: error)
    }

    #if os(iOS)
    public func sessionWatchStateDidChange(_ session: WCSession) {
        reachabilityChanged(describedAs: "the watch state changed")
    }

    public func sessionDidBecomeInactive(_ session: WCSession) {}

    public func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
    #endif
}
#endif
