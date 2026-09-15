import Foundation
import HydrationPairedDevice

public final class RecordingPairedDeviceChannel: PairedDeviceChannel, @unchecked Sendable {
    private var messages: [PairedDeviceMessage] = []
    private var receive: ReceivePairedDeviceMessage?
    private var sendOnReachable: OnPairedDeviceReachable?
    private let lock = NSLock()

    public init() {}

    public var sent: [PairedDeviceMessage] {
        lock.lock()
        defer { lock.unlock() }
        return messages
    }

    public var sentChanges: [DrinkChangeMessage] {
        sent.compactMap { message in
            guard case .change(let change) = message else { return nil }
            return change
        }
    }

    public var sentSnapshots: [DaySnapshotMessage] {
        sent.compactMap { message in
            guard case .daySnapshot(let snapshot) = message else { return nil }
            return snapshot
        }
    }

    public func send(_ message: PairedDeviceMessage) {
        lock.lock()
        messages.append(message)
        lock.unlock()
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

    public func becomeReachable() async {
        lock.lock()
        let send = self.sendOnReachable
        lock.unlock()
        await send?()
    }

    public func deliver(_ message: PairedDeviceMessage) async {
        lock.lock()
        let receive = self.receive
        lock.unlock()
        await receive?(message)
    }
}
