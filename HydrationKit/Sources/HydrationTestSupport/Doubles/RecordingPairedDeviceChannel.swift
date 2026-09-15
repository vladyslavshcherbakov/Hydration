import Foundation
import HydrationPairedDevice

public final class RecordingPairedDeviceChannel: PairedDeviceChannel, @unchecked Sendable {
    private var messages: [PairedDeviceMessage] = []
    private var receive: ReceiveEncodedMessage?
    private var sendOnReachable: OnPairedDeviceReachable?
    private let lock = NSLock()

    public init() {}

    public var sent: [PairedDeviceMessage] {
        lock.lock()
        defer { lock.unlock() }
        return messages
    }

    public var sentDrinks: [DrinkMessage] {
        sent.compactMap { message in
            guard case .drinkLogged(let drink) = message.content else { return nil }
            return drink
        }
    }

    public var sentRemovals: [DrinkRemovalMessage] {
        sent.compactMap { message in
            guard case .drinkRemoved(let removal) = message.content else { return nil }
            return removal
        }
    }

    public var sentSnapshots: [DayOfDrinksMessage] {
        sent.compactMap { message in
            guard case .daySnapshot(let day) = message.content else { return nil }
            return day
        }
    }

    public func send(_ message: PairedDeviceMessage) {
        lock.lock()
        messages.append(message)
        lock.unlock()
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

    public func becomeReachable() async {
        lock.lock()
        let send = self.sendOnReachable
        lock.unlock()
        await send?()
    }

    public func deliver(_ message: PairedDeviceMessage) async throws {
        let payload = try PairedDeviceMessageCoder.encode(message)
        await deliver(payload)
    }

    public func deliver(_ payload: Data) async {
        lock.lock()
        let receive = self.receive
        lock.unlock()
        await receive?(payload)
    }
}
