import CoreData
import HydrationDomain

public final class CoreDataDrinkRepository: DrinkRepository, LocalDrinkWriter, @unchecked Sendable {
    private let coreDataStack: CoreDataStack
    private let log: HydrationLog

    private var container: NSPersistentContainer {
        coreDataStack.container
    }

    public init(coreDataStack: CoreDataStack, log: HydrationLog) {
        self.coreDataStack = coreDataStack
        self.log = log
    }

    public func entries(in range: DateInterval) async throws -> [DrinkEntry] {
        try await fetchDTOs(in: range)
            .compactMap(readable)
            .sorted { $0.recordedAt < $1.recordedAt }
    }

    public func save(_ entry: DrinkEntry) async throws {
        let dto = DrinkEntryMapper.toDTO(entry)
        let context = container.newBackgroundContext()
        try await context.perform {
            let existingManagedEntry = try context.fetch(Self.request(forID: entry.id)).first
            DrinkEntryMapper.apply(dto, to: existingManagedEntry ?? CDDrinkEntry(context: context))
            try context.save()
        }
    }

    public func delete(id: UUID) async throws {
        let context = container.newBackgroundContext()
        try await context.perform {
            for managedEntry in try context.fetch(Self.request(forID: id)) {
                context.delete(managedEntry)
            }
            try context.save()
        }
    }

    private func readable(_ dto: DrinkEntryDTO) -> DrinkEntry? {
        do {
            return try DrinkEntryMapper.toDomain(dto)
        } catch {
            log.write(.warning, "stored record \(dto.id?.uuidString ?? "without an id") left out of the day: \(error)")
            return nil
        }
    }

    private func fetchDTOs(in range: DateInterval) async throws -> [DrinkEntryDTO] {
        let context = container.newBackgroundContext()
        return try await context.perform {
            try context.fetch(Self.request(in: range)).map(DrinkEntryMapper.toDTO)
        }
    }

    private static func request(forID id: UUID) -> NSFetchRequest<CDDrinkEntry> {
        let request = NSFetchRequest<CDDrinkEntry>(entityName: CoreDataStack.entityName)
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        return request
    }

    private static func request(in range: DateInterval) -> NSFetchRequest<CDDrinkEntry> {
        let request = NSFetchRequest<CDDrinkEntry>(entityName: CoreDataStack.entityName)
        request.predicate = NSPredicate(
            format: "day >= %@ AND day < %@",
            range.start as NSDate,
            range.end as NSDate
        )
        request.sortDescriptors = [NSSortDescriptor(key: "recordedAt", ascending: true)]
        return request
    }
}
