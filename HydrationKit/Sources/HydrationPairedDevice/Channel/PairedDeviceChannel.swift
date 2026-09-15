import Foundation

public typealias ReceiveEncodedMessage = @Sendable (Data) async -> Void
public typealias OnPairedDeviceReachable = @Sendable () async -> Void

public protocol PairedDeviceChannel: Sendable {
    func send(_ message: PairedDeviceMessage)
    func startReceiving(_ receive: @escaping ReceiveEncodedMessage)
    func whenPairedDeviceBecomesReachable(_ send: @escaping OnPairedDeviceReachable)
}

public struct NoPairedDeviceChannel: PairedDeviceChannel {
    public init() {}

    public func send(_ message: PairedDeviceMessage) {}

    public func startReceiving(_ receive: @escaping ReceiveEncodedMessage) {}

    public func whenPairedDeviceBecomesReachable(_ send: @escaping OnPairedDeviceReachable) {}
}
