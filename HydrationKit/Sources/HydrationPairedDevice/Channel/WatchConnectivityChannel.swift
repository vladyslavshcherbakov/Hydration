#if canImport(WatchConnectivity)
import Foundation
import HydrationDomain
import WatchConnectivity

public final class WatchConnectivityChannel: NSObject, PairedDeviceChannel, @unchecked Sendable {
    private let session: WCSession
    private let log: HydrationLog
    private let lock = NSLock()
    private var receive: ReceiveDrinkChange?
    private var resend: SendCurrentDrinks?

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

    public func send(_ message: DrinkChangeMessage) {
        guard session.isReachable else {
            log.write(.info, "queueing a change for the paired device, it is not reachable, session is \(describe(session)): \(message.dictionary)")
            session.transferUserInfo(message.dictionary)
            return
        }

        log.write(.info, "sending a change to the paired device by message, session is \(describe(session)): \(message.dictionary)")
        session.sendMessage(
            message.dictionary,
            replyHandler: nil,
            errorHandler: { [log, session] error in
                log.write(.warning, "the paired device did not take the change now, queueing it: \(error)")
                session.transferUserInfo(message.dictionary)
            }
        )
    }

    public func startReceiving(_ receive: @escaping ReceiveDrinkChange) {
        lock.lock()
        self.receive = receive
        lock.unlock()
    }

    public func whenPairedDeviceBecomesReachable(_ resend: @escaping SendCurrentDrinks) {
        lock.lock()
        self.resend = resend
        lock.unlock()
    }

    private func pairedDeviceBecameReachable() {
        lock.lock()
        let resend = self.resend
        lock.unlock()
        guard let resend else {
            log.write(.warning, "the paired device became reachable before anything was listening for it, today's drinks were not resent")
            return
        }
        Task { await resend() }
    }
}

extension WatchConnectivityChannel: WCSessionDelegate {
    public func sessionReachabilityDidChange(_ session: WCSession) {
        guard session.isReachable else {
            log.write(.info, "the paired device is no longer reachable, nothing is being resent, session is \(describe(session))")
            return
        }
        log.write(.info, "the paired device became reachable, resending today's drinks, session is \(describe(session))")
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
            log.write(.warning, "a change arrived from the paired device before anything was listening")
            return
        }
        log.write(.info, "a change arrived from the paired device by \(delivery): \(userInfo)")
        Task { await receive(DrinkChangeMessage(dictionary: userInfo)) }
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
            log.write(.info, "the watch state changed and it is not reachable, nothing is being resent, session is \(describe(session))")
            return
        }
        log.write(.info, "the watch state changed and it is reachable, resending today's drinks, session is \(describe(session))")
        pairedDeviceBecameReachable()
    }

    public func sessionDidBecomeInactive(_ session: WCSession) {}

    public func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
    #endif
}
#endif
