#if canImport(WidgetKit)
import Foundation
import HydrationDomain
import HydrationPersistence
import WidgetKit

public enum WidgetComposition {

    private static let root: CompositionRoot = {
        let log = ConsoleLog(category: "hydration-widget")
        let coreDataStack = CoreDataStack.forLaunch(
            appGroup: AppGroup.identifier,
            arguments: ProcessInfo.processInfo.arguments
        )
        let observedRepository = ObservedDrinkRepository(localStorage: CoreDataDrinkRepository(coreDataStack: coreDataStack, log: log))
        log.write(
            .info,
            "the widget started, sharing \(AppGroup.identifier), store at \(coreDataStack.storeURL?.path ?? "an unknown path")"
        )
        return CompositionRoot(
            repository: observedRepository,
            changes: observedRepository,
            log: log,
            dateProvider: SystemDateProvider()
        )
    }()

    // MARK: - Public

    public static func fetchTodayProgress() -> FetchDayProgressUseCase {
        root.makeFetchDay()
    }

    public static func addDrink() -> AddDrinkUseCase {
        root.makeAddDrink()
    }

    public static func presenter() -> WidgetTodayPresenter {
        WidgetTodayPresenter(calendar: root.calendar, locale: root.locale)
    }

    public static func currentDay() -> CurrentDay {
        root.makeCurrentDay()
    }

    public static func dateProvider() -> DateProvider {
        root.dateProvider
    }

    public static func log() -> HydrationLog {
        root.log
    }
}
#endif
