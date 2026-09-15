import Foundation
import HydrationDesignSystem
import HydrationDomain

public struct DayPresenter: Sendable {
    private let calendar: Calendar
    private let locale: Locale

    // MARK: - Public

    public init(calendar: Calendar, locale: Locale) {
        self.calendar = calendar
        self.locale = locale
    }

    public func presentLoading() -> DayViewState {
        DayViewState(
            title: "Today",
            historyTitle: historyTitle,
            situation: .loading(
                DayViewState.Loading(
                    message: "Loading your day…",
                    accessibilityLabel: "Loading hydration progress"
                )
            )
        )
    }

    public func present(progress: DailyProgress) -> DayViewState {
        DayViewState(
            title: title(for: progress),
            historyTitle: historyTitle,
            situation: .content(content(of: progress))
        )
    }

    public func present(error: Error) -> DayViewState {
        DayViewState(
            title: "Today",
            historyTitle: historyTitle,
            situation: .failed(
                DayViewState.Failure(
                    message: message(for: error),
                    retryTitle: "Try again",
                    accent: .critical,
                    accessibilityLabel: message(for: error)
                )
            )
        )
    }

    // MARK: - Private

    private var historyTitle: String {
        "History"
    }

    private var quickAddTitle: String {
        "Add \(VolumeFormatting.milliliters(.quickAdd))"
    }

    private func content(of progress: DailyProgress) -> DayViewState.Content {
        let status = statusText(for: progress)

        return DayViewState.Content(
            totalText: "\(liters(progress.total)) L",
            goalText: "of \(liters(progress.goal.target)) L",
            statusText: status,
            fraction: progress.fraction,
            accent: SemanticColor(status: progress.status),
            quickAddTitle: quickAddTitle,
            isQuickAddEnabled: progress.canAddMore,
            entries: entries(of: progress),
            footnote: footnote(for: progress),
            accessibilityLabel: "\(liters(progress.total)) liters of \(liters(progress.goal.target)) liters, \(status)"
        )
    }

    private func title(for progress: DailyProgress) -> String {
        guard !progress.isToday else { return "Today" }
        return dayText(progress.day)
    }

    private func liters(_ volume: Volume) -> String {
        VolumeFormatting.liters(volume, locale: locale)
    }

    private func entries(of progress: DailyProgress) -> [DayViewState.Entry] {
        progress.entries.reversed().map { entry in
            DayViewState.Entry(
                id: entry.id,
                amountText: VolumeFormatting.milliliters(entry.volume),
                timeText: recordedText(for: entry)
            )
        }
    }

    private func recordedText(for entry: DrinkEntry) -> String {
        let time = VolumeFormatting.time(entry.recordedAt, calendar: calendar)
        guard !calendar.isDate(entry.day, inSameDayAs: entry.recordedAt) else { return time }
        return "\(dayText(entry.recordedAt)), \(time)"
    }

    private func dayText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.locale = locale
        formatter.dateFormat = "d MMM"
        return formatter.string(from: date)
    }

    private func footnote(for progress: DailyProgress) -> String {
        guard !progress.entries.isEmpty else { return "No drinks logged yet" }
        return "\(progress.entries.count) drinks logged"
    }

    private func statusText(for progress: DailyProgress) -> String {
        switch progress.status {
        case .behind:
            return "\(VolumeFormatting.milliliters(progress.deficit)) behind schedule"
        case .onTrack:
            return "On track, \(VolumeFormatting.milliliters(progress.remaining)) to go"
        case .reached:
            return "Daily goal reached"
        case .excessive:
            return "Well above your goal, consider slowing down"
        }
    }

    private func message(for error: Error) -> String {
        switch error {
        case HydrationError.safetyLimitReached:
            return "You have reached the daily safety limit"
        case HydrationError.invalidVolume:
            return "That amount is not valid"
        default:
            return "Could not load your hydration data"
        }
    }
}
