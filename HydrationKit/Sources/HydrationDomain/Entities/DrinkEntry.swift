import Foundation

public struct DrinkEntry: Equatable, Hashable, Sendable, Identifiable {
    public let id: UUID
    public let volume: Volume
    public let day: Date
    public let recordedAt: Date

    public init(id: UUID, volume: Volume, day: Date, recordedAt: Date) {
        self.id = id
        self.volume = volume
        self.day = day
        self.recordedAt = recordedAt
    }
}
