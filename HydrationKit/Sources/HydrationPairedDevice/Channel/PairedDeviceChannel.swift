import Foundation

public typealias ReceiveDrinkChange = @Sendable (DrinkChangeMessage) async -> Void
public typealias SendCurrentDrinks = @Sendable () async -> Void

public protocol PairedDeviceChannel: Sendable {
    func send(_ message: DrinkChangeMessage)
    func startReceiving(_ receive: @escaping ReceiveDrinkChange)
    func whenPairedDeviceBecomesReachable(_ resend: @escaping SendCurrentDrinks)
}

public struct NoPairedDeviceChannel: PairedDeviceChannel {
    public init() {}

    public func send(_ message: DrinkChangeMessage) {}

    public func startReceiving(_ receive: @escaping ReceiveDrinkChange) {}

    public func whenPairedDeviceBecomesReachable(_ resend: @escaping SendCurrentDrinks) {}
}
