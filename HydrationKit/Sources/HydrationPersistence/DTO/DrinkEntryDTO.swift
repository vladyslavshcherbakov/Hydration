import Foundation
import HydrationDomain

struct DrinkEntryDTO: Equatable, Sendable {
    let id: UUID?
    let amountML: Int64
    let day: Date?
    let recordedAt: Date?
    let schemaVersion: Int16

    init(id: UUID?, amountML: Int64, day: Date?, recordedAt: Date?, schemaVersion: Int16) {
        self.id = id
        self.amountML = amountML
        self.day = day
        self.recordedAt = recordedAt
        self.schemaVersion = schemaVersion
    }
}
