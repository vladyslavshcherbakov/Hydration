#if canImport(WatchConnectivity)
import Foundation
import HydrationPairedDevice
import WatchConnectivity

public final class RecordingPairedDeviceSession: PairedDeviceSession, @unchecked Sendable {
    public var isReachable: Bool
    public var refuseSends: Error?

    public private(set) var started = false
    public private(set) var sent: [[String: Any]] = []
    public private(set) var queued: [[String: Any]] = []

    // MARK: - Public

    public init(isReachable: Bool = true) {
        self.isReachable = isReachable
    }

    public var stateDescription: String {
        "a recorded session, reachable \(isReachable)"
    }

    public func start(with delegate: WCSessionDelegate) {
        started = true
    }

    public func send(_ userInfo: [String: Any], onFailure: @escaping (Error) -> Void) {
        sent.append(userInfo)
        if let refuseSends {
            onFailure(refuseSends)
        }
    }

    public func queue(_ userInfo: [String: Any]) {
        queued.append(userInfo)
    }

    public func payload(of userInfo: [String: Any]) -> Data? {
        userInfo["payload"] as? Data
    }
}
#endif
