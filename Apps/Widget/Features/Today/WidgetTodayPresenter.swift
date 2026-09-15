import Foundation
import HydrationDesignSystem
import HydrationDomain

public struct WidgetTodayPresenter: Sendable {
    private let calendar: Calendar
    private let locale: Locale

    // MARK: - Public
    public init(calendar: Calendar, locale: Locale) {
        self.calendar = calendar
        self.locale = locale
    }

    public func presentPlaceholder() -> WidgetTodayViewState {
        WidgetTodayViewState(
            title: title,
            situation: .content(
                WidgetTodayViewState.Content(
                    totalText: "1.2 L",
                    goalText: "of 2.5 L",
                    statusText: "On track",
                    fraction: 0.48,
                    accent: .neutral,
                    quickAddTitle: quickAddTitle,
                    isQuickAddEnabled: false,
                    footnote: "Updated 12:00",
                    accessibilityLabel: "Hydration placeholder"
                )
            )
        )
    }

    public func present(progress: DailyProgress) -> WidgetTodayViewState {
        WidgetTodayViewState(title: title, situation: .content(content(of: progress)))
    }

    public func present(error: Error) -> WidgetTodayViewState {
        WidgetTodayViewState(
            title: title,
            situation: .failed(
                WidgetTodayViewState.Failure(
                    message: "Open the app",
                    accent: .critical,
                    accessibilityLabel: "Hydration data unavailable"
                )
            )
        )
    }

    // MARK: - Private
    private var title: String {
        "Water"
    }

    private var quickAddTitle: String {
        "+\(Volume.quickAdd.milliliters)"
    }

    private func content(of progress: DailyProgress) -> WidgetTodayViewState.Content {
        let status = statusText(for: progress)

        return WidgetTodayViewState.Content(
            totalText: "\(liters(progress.total)) L",
            goalText: "of \(liters(progress.goal.target)) L",
            statusText: status,
            fraction: progress.fraction,
            accent: SemanticColor(status: progress.status),
            quickAddTitle: quickAddTitle,
            isQuickAddEnabled: progress.canAddMore,
            footnote: "Updated \(VolumeFormatting.time(progress.evaluatedAt, calendar: calendar))",
            accessibilityLabel: "\(liters(progress.total)) of \(liters(progress.goal.target)), \(status)"
        )
    }

    private func liters(_ volume: Volume) -> String {
        VolumeFormatting.liters(volume, locale: locale)
    }

    private func statusText(for progress: DailyProgress) -> String {
        switch progress.status {
        case .behind: return "\(progress.deficit.milliliters) ml behind"
        case .onTrack: return "On track"
        case .reached: return "Goal reached"
        case .excessive: return "Above goal"
        }
    }
}
