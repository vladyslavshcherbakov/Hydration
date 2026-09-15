import Foundation
import HydrationPairedDevice

public final class RecordingPairedDeviceChannel: PairedDeviceChannel, @unchecked Sendable {
    private var messages: [DrinkChangeMessage] = []
    private var receive: ReceiveDrinkChange?
    private var resend: SendCurrentDrinks?
    private let lock = NSLock()

    public init() {}

    public var sent: [DrinkChangeMessage] {
        lock.lock()
        defer { lock.unlock() }
        return messages
    }

    public func send(_ message: DrinkChangeMessage) {
        lock.lock()
        messages.append(message)
        lock.unlock()
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

    public func becomeReachable() async {
        lock.lock()
        let resend = self.resend
        lock.unlock()
        await resend?()
    }

    public func deliver(_ message: DrinkChangeMessage) async {
        lock.lock()
        let receive = self.receive
        lock.unlock()
        await receive?(message)
    }
}
