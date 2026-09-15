#if canImport(WatchConnectivity)
import Foundation
import WatchConnectivity

public protocol PairedDeviceSession: AnyObject {
    var isReachable: Bool { get }
    var stateDescription: String { get }

    func start(with delegate: WCSessionDelegate)
    func send(_ userInfo: [String: Any], onFailure: @escaping (Error) -> Void)
    func queue(_ userInfo: [String: Any])
}

// MARK: - WCSession + PairedDeviceSession

extension WCSession: PairedDeviceSession {
    public var stateDescription: String {
        var parts = ["state \(activationState.rawValue)", "reachable \(isReachable)"]
        #if os(iOS)
        parts.append("paired \(isPaired)")
        parts.append("watch app installed \(isWatchAppInstalled)")
        #endif
        return parts.joined(separator: ", ")
    }

    public func start(with delegate: WCSessionDelegate) {
        self.delegate = delegate
        activate()
    }

    public func send(_ userInfo: [String: Any], onFailure: @escaping (Error) -> Void) {
        sendMessage(userInfo, replyHandler: nil, errorHandler: onFailure)
    }

    public func queue(_ userInfo: [String: Any]) {
        _ = transferUserInfo(userInfo)
    }
}
#endif
