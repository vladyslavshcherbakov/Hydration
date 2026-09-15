#if canImport(WatchConnectivity)
import Foundation
import HydrationDomain
import WatchConnectivity

public final class WatchConnectivityChannel: NSObject, PairedDeviceChannel, @unchecked Sendable {
    private let session: WCSession
    private let log: HydrationLog
    private let lock = NSLock()
    private var receive: ReceivePairedDeviceMessage?
    private var sendOnReachable: OnPairedDeviceReachable?

    public init?(session: WCSession = .default, log: HydrationLog) {
        guard WCSession.isSupported() else {
            log.write(.warning, "this device has no WatchConnectivity session, no change will reach a paired device")
            return nil
        }
        self.session = session
        self.log = log
        super.init()
        session.delegate = self
        session.activate()
    }

    public func send(_ message: PairedDeviceMessage) {
        guard session.isReachable else {
            log.write(.info, "queueing \(message) for the paired device, it is not reachable, session is \(describe(session))")
            session.transferUserInfo(message.dictionary)
            return
        }

        log.write(.info, "sending \(message) to the paired device by message, session is \(describe(session))")
        session.sendMessage(
            message.dictionary,
            replyHandler: nil,
            errorHandler: { [log, session] error in
                log.write(.warning, "the paired device did not take \(message) now, queueing it: \(error)")
                session.transferUserInfo(message.dictionary)
            }
        )
    }

    public func startReceiving(_ receive: @escaping ReceivePairedDeviceMessage) {
        lock.lock()
        self.receive = receive
        lock.unlock()
    }

    public func whenPairedDeviceBecomesReachable(_ send: @escaping OnPairedDeviceReachable) {
        lock.lock()
        self.sendOnReachable = send
        lock.unlock()
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

extension WatchConnectivityChannel: WCSessionDelegate {
    public func sessionReachabilityDidChange(_ session: WCSession) {
        guard session.isReachable else {
            log.write(.info, "the paired device is no longer reachable, nothing is being sent to it, session is \(describe(session))")
            return
        }
        log.write(.info, "the paired device became reachable, session is \(describe(session))")
        pairedDeviceBecameReachable()
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
        guard let error else {
            log.write(.info, "a queued transfer reached the paired device")
            return
        }
        log.write(.error, "a queued transfer never reached the paired device: \(error)")
    }

    private func deliver(_ userInfo: [String: Any], arrivedBy delivery: String) {
        lock.lock()
        let receive = self.receive
        lock.unlock()
        guard let receive else {
            log.write(.warning, "a message arrived from the paired device before anything was listening: \(userInfo)")
            return
        }

        do {
            let message = try PairedDeviceMessage(dictionary: userInfo)
            log.write(.info, "\(message) arrived from the paired device by \(delivery)")
            Task { await receive(message) }
        } catch {
            log.write(.warning, "a message from the paired device could not be read: \(error), message was \(userInfo)")
        }
    }

    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error {
            log.write(.error, "the link to the paired device could not be activated: \(error)")
            return
        }
        log.write(.info, "the link to the paired device is ready, session is \(describe(session))")
    }

    private func describe(_ session: WCSession) -> String {
        var parts = ["state \(session.activationState.rawValue)", "reachable \(session.isReachable)"]
        #if os(iOS)
        parts.append("paired \(session.isPaired)")
        parts.append("watch app installed \(session.isWatchAppInstalled)")
        #endif
        return parts.joined(separator: ", ")
    }

    #if os(iOS)
    public func sessionWatchStateDidChange(_ session: WCSession) {
        guard session.isReachable else {
            log.write(.info, "the watch state changed and it is not reachable, nothing is being sent to it, session is \(describe(session))")
            return
        }
        log.write(.info, "the watch state changed and it is reachable, session is \(describe(session))")
        pairedDeviceBecameReachable()
    }

    public func sessionDidBecomeInactive(_ session: WCSession) {}

    public func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
    #endif
}
#endif
