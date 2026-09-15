#if canImport(WidgetKit)
import HydrationDomain
import WidgetKit

struct HydrationEntry: TimelineEntry {
    let date: Date
    let viewData: WidgetTodayViewData
}

// MARK: - HydrationTimelineProvider

struct HydrationTimelineProvider: TimelineProvider {
    static let refreshInterval: TimeInterval = 15 * 60

    private let fetchProgress: FetchDayProgressUseCase
    private let mapper: WidgetTodayViewDataMapper
    private let dateProvider: DateProvider
    private let currentDay: CurrentDay
    private let log: HydrationLog

    init(
        fetchProgress: FetchDayProgressUseCase,
        mapper: WidgetTodayViewDataMapper,
        dateProvider: DateProvider,
        currentDay: CurrentDay,
        log: HydrationLog
    ) {
        self.fetchProgress = fetchProgress
        self.mapper = mapper
        self.dateProvider = dateProvider
        self.currentDay = currentDay
        self.log = log
    }

    func placeholder(in context: Context) -> HydrationEntry {
        HydrationEntry(date: dateProvider.now(), viewData: mapper.placeholder())
    }

    func getSnapshot(in context: Context, completion: @escaping (HydrationEntry) -> Void) {
        Task { completion(await makeEntry()) }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<HydrationEntry>) -> Void) {
        Task { completion(await makeTimeline()) }
    }

    func makeTimeline() async -> Timeline<HydrationEntry> {
        let entry = await makeEntry()
        let nextRefresh = entry.date.addingTimeInterval(Self.refreshInterval)
        log.write(.info, "the widget timeline shows \(entry.viewData) read at \(entry.date), next refresh at \(nextRefresh)")
        return Timeline(entries: [entry], policy: .after(nextRefresh))
    }

    func makeEntry() async -> HydrationEntry {
        do {
            let progress = try await fetchProgress.execute(day: currentDay.start())
            return HydrationEntry(date: progress.evaluatedAt, viewData: mapper.viewData(for: progress))
        } catch {
            log.write(.error, "the widget could not read today's progress: \(error)")
            return HydrationEntry(date: dateProvider.now(), viewData: mapper.viewData(for: error))
        }
    }
}
#endif
