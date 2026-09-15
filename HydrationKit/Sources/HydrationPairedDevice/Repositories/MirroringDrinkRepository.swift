import Foundation
import HydrationDomain

public final class MirroringDrinkRepository: DrinkRepository {
    private let localStorage: DrinkRepository
    private let pairedDevice: PairedDeviceChannel

    public init(localStorage: DrinkRepository, pairedDevice: PairedDeviceChannel) {
        self.localStorage = localStorage
        self.pairedDevice = pairedDevice
    }

    public func entries(in range: DateInterval) async throws -> [DrinkEntry] {
        try await localStorage.entries(in: range)
    }

    public func save(_ entry: DrinkEntry) async throws {
        try await localStorage.save(entry)
        pairedDevice.send(.change(DrinkChangeMessageMapper.message(forLogging: entry)))
    }

    public func delete(id: UUID) async throws {
        try await localStorage.delete(id: id)
        pairedDevice.send(.change(DrinkChangeMessageMapper.message(forRemoving: id)))
    }
}
