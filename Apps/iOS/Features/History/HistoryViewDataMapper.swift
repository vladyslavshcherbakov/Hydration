import Foundation
import HydrationDesignSystem
import HydrationDomain

public struct HistoryViewDataMapper: Sendable {
    private let calendar: Calendar
    private let locale: Locale
    private let today: Date

    // MARK: - Public

    public init(calendar: Calendar, locale: Locale, today: Date) {
        self.calendar = calendar
        self.locale = locale
        self.today = today
    }

    public func loading() -> HistoryViewData {
        HistoryViewData(title: title, state: .loading)
    }

    public func viewData(for summaries: [DailySummary], selected: Date) -> HistoryViewData {
        HistoryViewData(title: title, state: .content(content(of: summaries, selected: selected)))
    }

    public func viewData(for error: Error) -> HistoryViewData {
        HistoryViewData(title: title, state: .failed("Could not load history"))
    }

    // MARK: - Private

    private var title: String {
        "History"
    }

    private func content(of summaries: [DailySummary], selected: Date) -> HistoryViewData.Content {
        let reached = summaries.filter(\.isGoalReached).count

        return HistoryViewData.Content(
            summaryText: "\(reached) of \(summaries.count) days on target",
            rows: summaries.map { row(for: $0, selected: selected) }
        )
    }

    private func row(for summary: DailySummary, selected: Date) -> HistoryViewData.Row {
        HistoryViewData.Row(
            id: summary.day,
            identifier: "history.row.\(identifierDate(summary.day))",
            dayText: dayText(summary.day),
            totalText: "\(VolumeFormatting.liters(summary.total, locale: locale)) L",
            fraction: summary.fraction,
            accent: summary.isGoalReached ? .positive : .warning,
            badgeText: summary.isGoalReached ? "Goal" : nil,
            isSelected: summary.day == selected
        )
    }

    private func identifierDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private func dayText(_ date: Date) -> String {
        guard !calendar.isDate(date, inSameDayAs: today) else { return "Today" }

        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.locale = locale
        formatter.dateFormat = "EEE, d MMM"
        return formatter.string(from: date)
    }
}
