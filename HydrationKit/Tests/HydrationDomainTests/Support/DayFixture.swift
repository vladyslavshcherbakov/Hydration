import Foundation
import HydrationDomain

enum DayFixture {
    static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        calendar.locale = Locale(identifier: "en_US_POSIX")
        return calendar
    }()

    static var day: Date {
        calendar.dayInterval(for: Date(timeIntervalSince1970: 1_700_000_000)).start
    }

    static func moment(hour: Int, minute: Int = 0, dayOffset: Int = 0) -> Date {
        let start = calendar.date(byAdding: .day, value: dayOffset, to: day)!
        return calendar.date(byAdding: DateComponents(hour: hour, minute: minute), to: start)!
    }

    static func drink(_ milliliters: Int, at hour: Int, dayOffset: Int = 0) -> DrinkEntry {
        DrinkEntry(
            id: UUID(),
            volume: Volume(milliliters: milliliters)!,
            day: calendar.date(byAdding: .day, value: dayOffset, to: day)!,
            recordedAt: moment(hour: hour, dayOffset: dayOffset)
        )
    }

    static func progress(
        _ drinks: [DrinkEntry],
        at hour: Int,
        goal: HydrationGoal = .standard,
        dayOffset: Int = 0
    ) -> DailyProgress {
        DailyProgress(
            day: calendar.date(byAdding: .day, value: dayOffset, to: day)!,
            goal: goal,
            entries: drinks,
            evaluatedAt: moment(hour: hour),
            calendar: calendar
        )
    }
}
