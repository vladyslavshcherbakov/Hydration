import Foundation
import HydrationDomain
import HydrationPersistence
import HydrationTestSupport
@testable import Hydration

final class EndToEndEnvironment {
    let storeURL: URL
    let dateProvider: MutableDateProvider
    let calendar: Calendar
    let locale: Locale
    let log = RecordingLog()

    init(now: Date = PersistenceEnvironment.referenceNow) {
        let locale = Locale(identifier: "en_US_POSIX")
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        calendar.locale = locale

        self.calendar = calendar
        self.locale = locale
        self.dateProvider = MutableDateProvider(now: now)
        self.storeURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(UUID().uuidString).sqlite")
    }

    func makeCompositionRoot() -> CompositionRoot {
        let coreDataStack = CoreDataStack(storeURL: storeURL)
        let observedRepository = ObservedDrinkRepository(localStorage: CoreDataDrinkRepository(coreDataStack: coreDataStack, log: log))
        return CompositionRoot(
            repository: observedRepository,
            changes: observedRepository,
            log: log,
            dateProvider: dateProvider,
            calendar: calendar,
            goal: .standard
        )
    }

    func date(hour: Int, minute: Int = 0, dayOffset: Int = 0) -> Date {
        let dayStart = calendar.dayInterval(for: dateProvider.now()).start
        let shifted = calendar.date(byAdding: .day, value: dayOffset, to: dayStart)!
        return calendar.date(byAdding: DateComponents(hour: hour, minute: minute), to: shifted)!
    }

    func removeStore() {
        CoreDataStack.removeStore(at: storeURL)
    }
}
