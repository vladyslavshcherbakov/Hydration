import Foundation
import HydrationDesignSystem
import HydrationDomain

public struct WatchTodayViewDataMapper: Sendable {
    public static let defaultPresets = [200, 350, 500]

    private let calendar: Calendar
    private let locale: Locale
    private let presets: [Int]

    // MARK: - Public

    public init(calendar: Calendar, locale: Locale, presets: [Int] = WatchTodayViewDataMapper.defaultPresets) {
        self.calendar = calendar
        self.locale = locale
        self.presets = presets
    }

    public func loading() -> WatchTodayViewData {
        WatchTodayViewData(
            title: title,
            state: .loading(WatchTodayViewData.Loading(accessibilityLabel: "Loading"))
        )
    }

    public func viewData(for progress: DailyProgress) -> WatchTodayViewData {
        WatchTodayViewData(title: title, state: .content(content(of: progress)))
    }

    public func viewData(for error: Error) -> WatchTodayViewData {
        WatchTodayViewData(
            title: title,
            state: .failed(
                WatchTodayViewData.Failure(
                    message: message(for: error),
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

    private func content(of progress: DailyProgress) -> WatchTodayViewData.Content {
        let status = statusText(for: progress)

        return WatchTodayViewData.Content(
            totalText: liters(progress.total),
            goalText: "/ \(liters(progress.goal.target))",
            statusText: status,
            fraction: progress.fraction,
            accent: SemanticColor(status: progress.status),
            presets: presets.map { preset(for: $0, within: progress) },
            undoTitle: undoTitle(for: progress),
            isUndoEnabled: progress.lastEntry != nil,
            accessibilityLabel: "\(liters(progress.total)) of \(liters(progress.goal.target)), \(status)"
        )
    }

    private func preset(for amount: Int, within progress: DailyProgress) -> WatchTodayViewData.Preset {
        WatchTodayViewData.Preset(
            milliliters: amount,
            title: "+\(amount)",
            isEnabled: progress.total.milliliters + amount <= Volume.dailySafetyLimit.milliliters
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
        case .excessive: return "Above your goal"
        }
    }

    private func undoTitle(for progress: DailyProgress) -> String {
        guard let last = progress.lastEntry else { return "Nothing to undo" }
        return "Undo \(last.volume.milliliters) ml"
    }

    private func message(for error: Error) -> String {
        switch error {
        case HydrationError.safetyLimitReached: return "Limit"
        case HydrationError.nothingToRemove: return "Nothing to undo"
        default: return "Retry"
        }
    }
}
