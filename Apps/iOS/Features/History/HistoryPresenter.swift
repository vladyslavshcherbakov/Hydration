import Foundation
import HydrationDomain

public struct HistoryPresenter: Sendable {
    private let calendar: Calendar
    private let locale: Locale
    private let today: Date

    public init(calendar: Calendar, locale: Locale, today: Date) {
        self.calendar = calendar
        self.locale = locale
        self.today = today
    }

    public func present(summaries: [DailySummary], selected: Date) -> HistoryViewState {
        let reached = summaries.filter(\.isGoalReached).count

        return HistoryViewState(
            title: "History",
            summaryText: "\(reached) of \(summaries.count) days on target",
            rows: summaries.map { row(for: $0, selected: selected) },
            emptyText: summaries.isEmpty ? "Nothing logged yet" : nil
        )
    }

    public func present(error: Error) -> HistoryViewState {
        HistoryViewState(
            title: "History",
            summaryText: "",
            rows: [],
            emptyText: "Could not load history"
        )
    }

    private func row(for summary: DailySummary, selected: Date) -> HistoryViewState.Row {
        HistoryViewState.Row(
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
