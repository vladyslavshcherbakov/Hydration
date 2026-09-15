#if os(iOS)
import SwiftUI

@MainActor
public final class ScreenFactory {
    private let root: CompositionRoot
    private let coordinator: AppCoordinator

    public init(root: CompositionRoot, coordinator: AppCoordinator) {
        self.root = root
        self.coordinator = coordinator
    }

    func makeDayViewModel() -> DayViewModel {
        DayViewModel(
            day: coordinator.selectedDay,
            fetchProgress: root.makeFetchDay(),
            addDrink: root.makeAddDrink(),
            removeDrink: root.makeRemoveDrink(),
            mapper: DayViewDataMapper(calendar: root.calendar, locale: root.locale),
            calendar: root.calendar,
            changes: root.changes,
            log: root.log,
            onHistoryRequested: { [coordinator] in coordinator.show(.history) }
        )
    }

    func makeHistoryViewModel() -> HistoryViewModel {
        HistoryViewModel(
            fetchHistory: root.makeFetchHistory(),
            mapper: HistoryViewDataMapper(calendar: root.calendar, locale: root.locale, today: root.makeCurrentDay().start()),
            changes: root.changes,
            log: root.log,
            selectedDay: coordinator.selectedDay,
            onDaySelected: { [coordinator] day in coordinator.select(day: day) }
        )
    }

    func makeDayScreen(showsHistory: Bool) -> some View {
        DayScreen(viewModel: self.makeDayViewModel(), showsHistory: showsHistory)
    }

    @ViewBuilder
    func makeStackScreen(for route: AppRoute) -> some View {
        switch route {
        case .history:
            HistoryScreen(viewModel: self.makeHistoryViewModel(), coordinator: coordinator)
        }
    }

    @ViewBuilder
    func makeDetailScreen(for route: AppRoute) -> some View {
        switch route {
        case .history:
            HistoryUIKitScreen(coordinator: coordinator, viewModel: self.makeHistoryViewModel())
        }
    }
}
#endif
