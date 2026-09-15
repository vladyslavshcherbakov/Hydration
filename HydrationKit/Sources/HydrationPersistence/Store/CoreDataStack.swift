import CoreData
import HydrationDomain

public final class CoreDataStack {
    public static let entityName = "CDDrinkEntry"
    public static let useTestStoreArgument = "-uiTestStore"
    public static let resetStoreArgument = "-resetStore"

    public let container: NSPersistentContainer

    public convenience init(storeURL: URL) {
        let description = NSPersistentStoreDescription(url: storeURL)
        description.type = NSSQLiteStoreType
        self.init(description: description)
    }

    private init(description: NSPersistentStoreDescription) {
        container = NSPersistentContainer(name: "Hydration", managedObjectModel: CoreDataStack.model)

        description.shouldMigrateStoreAutomatically = true
        description.shouldInferMappingModelAutomatically = true
        description.setOption(FileProtectionType.completeUntilFirstUserAuthentication as NSObject,
                              forKey: NSPersistentStoreFileProtectionKey)
        container.persistentStoreDescriptions = [description]

        container.loadPersistentStores { loaded, error in
            if let error {
                preconditionFailure("store at \(loaded.url?.path ?? "unknown") could not be opened: \(error)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    public static func inMemory() -> CoreDataStack {
        let description = NSPersistentStoreDescription(url: URL(fileURLWithPath: "/dev/null"))
        description.type = NSInMemoryStoreType
        return CoreDataStack(description: description)
    }

    public static func forLaunch(appGroup: String, arguments: [String]) -> CoreDataStack {
        guard arguments.contains(useTestStoreArgument) else {
            return CoreDataStack(storeURL: sharedStoreURL(appGroup: appGroup))
        }

        if arguments.contains(resetStoreArgument) {
            removeStore(at: uiTestStoreURL)
        }

        return CoreDataStack(storeURL: uiTestStoreURL)
    }

    public static func sharedStoreURL(appGroup: String) -> URL {
        guard let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup) else {
            preconditionFailure("App Group container for \(appGroup) is unavailable")
        }
        return container.appendingPathComponent("Hydration.sqlite")
    }

    public static var uiTestStoreURL: URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("HydrationUITests.sqlite")
    }

    public static func removeStore(at url: URL) {
        let fileManager = FileManager.default
        for suffix in ["", "-wal", "-shm"] {
            try? fileManager.removeItem(at: URL(fileURLWithPath: url.path + suffix))
        }
    }

    static let model: NSManagedObjectModel = {
        let model = NSManagedObjectModel()
        let entity = NSEntityDescription()
        entity.name = entityName
        entity.managedObjectClassName = NSStringFromClass(CDDrinkEntry.self)
        entity.properties = [identifier, amount, day, recordedAt, schemaVersion]
        model.entities = [entity]
        return model
    }()

    private static var identifier: NSAttributeDescription {
        attribute(named: "id", type: .UUIDAttributeType, optional: true)
    }

    private static var amount: NSAttributeDescription {
        attribute(named: "amountML", type: .integer64AttributeType, optional: false, defaultValue: 0)
    }

    private static var day: NSAttributeDescription {
        attribute(named: "day", type: .dateAttributeType, optional: true)
    }

    private static var recordedAt: NSAttributeDescription {
        attribute(named: "recordedAt", type: .dateAttributeType, optional: true)
    }

    private static var schemaVersion: NSAttributeDescription {
        attribute(named: "schemaVersion", type: .integer16AttributeType, optional: false, defaultValue: 1)
    }

    private static func attribute(
        named name: String,
        type: NSAttributeType,
        optional: Bool,
        defaultValue: Any? = nil
    ) -> NSAttributeDescription {
        let attribute = NSAttributeDescription()
        attribute.name = name
        attribute.attributeType = type
        attribute.isOptional = optional
        attribute.defaultValue = defaultValue
        return attribute
    }
}
