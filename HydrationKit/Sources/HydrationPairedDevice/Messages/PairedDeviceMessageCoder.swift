import Foundation

public enum PairedDeviceMessageError: Error, Equatable {
    case unsupportedVersion(Int)
}

// MARK: - PairedDeviceMessageCoder
public enum PairedDeviceMessageCoder {
    public static func encode(_ message: PairedDeviceMessage) throws -> Data {
        try JSONEncoder().encode(message)
    }

    public static func decode(_ payload: Data) throws -> PairedDeviceMessage {
        let message = try JSONDecoder().decode(PairedDeviceMessage.self, from: payload)
        guard message.version <= PairedDeviceMessage.currentVersion else {
            throw PairedDeviceMessageError.unsupportedVersion(message.version)
        }
        return message
    }
}
