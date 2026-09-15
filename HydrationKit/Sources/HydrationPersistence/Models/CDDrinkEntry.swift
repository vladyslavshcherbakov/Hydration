import CoreData
import HydrationDomain

@objc(CDDrinkEntry)
final class CDDrinkEntry: NSManagedObject {
    @NSManaged var id: UUID?
    @NSManaged var amountML: Int64
    @NSManaged var day: Date?
    @NSManaged var recordedAt: Date?
    @NSManaged var schemaVersion: Int16
}
