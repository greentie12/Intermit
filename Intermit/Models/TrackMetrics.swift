import Foundation

/// Totals for completed fasts within one stretch of time, such as this month.
struct PeriodTotals: Equatable, Sendable {
    /// Number of completed fasts.
    var fasts = 0
    /// Full length of those fasts, in hours.
    var hours: Double = 0
    /// Distinct local calendar days on which one or more of those fasts ended.
    var days = 0
}

/// Everything the Track tab shows, worked out from the user's fasts.
///
/// Every completed fast belongs to the local calendar day on which it **ended**,
/// and all of its hours count toward that day. That keeps the numbers consistent:
/// a fast is never split across days or periods, an overnight fast counts as one
/// day fasted, and this month's totals are always part of this year's. Fasts still
/// in progress aren't counted until they end. See `Docs/TrackMetrics.md`.
struct TrackMetrics: Sendable {
    var lifetime: PeriodTotals
    var thisWeek: PeriodTotals
    var thisMonth: PeriodTotals
    var thisYear: PeriodTotals

    /// Last month from its first day up to the same moment as now, e.g. Oct 1–9
    /// when it's Nov 9, so a partial month is compared with an equally long one.
    var lastMonthToDate: PeriodTotals
    /// Last year from Jan 1 up to the same moment as now.
    var lastYearToDate: PeriodTotals

    var week: DateInterval
    var month: DateInterval
    var year: DateInterval

    /// Calendar days so far in each period, counting today.
    var daysElapsedInWeek: Int
    var daysElapsedInMonth: Int
    var daysElapsedInYear: Int

    /// The most recently started fast that hasn't ended yet.
    var ongoing: FastingSession?

    /// Whether there's anything at all to show.
    var hasData: Bool { lifetime.fasts > 0 || ongoing != nil }

    var weekDailyAverage: Double { thisWeek.hours / Double(max(daysElapsedInWeek, 1)) }
    var monthDailyAverage: Double { thisMonth.hours / Double(max(daysElapsedInMonth, 1)) }
    var yearDailyAverage: Double { thisYear.hours / Double(max(daysElapsedInYear, 1)) }

    /// - Parameters:
    ///   - calendar: Sets the time zone, first day of the week, and where days,
    ///     months, and years begin. Pass the user's current calendar.
    init(sessions: [FastingSession], now: Date = .now, calendar: Calendar = .current) {
        let completed = sessions.filter { !$0.isOngoing }
        ongoing = sessions.filter(\.isOngoing).max { $0.start < $1.start }

        let today = calendar.startOfDay(for: now)
        week = calendar.dateInterval(of: .weekOfYear, for: now) ?? DateInterval(start: today, duration: 0)
        month = calendar.dateInterval(of: .month, for: now) ?? DateInterval(start: today, duration: 0)
        year = calendar.dateInterval(of: .year, for: now) ?? DateInterval(start: today, duration: 0)

        func totals(from start: Date, to end: Date) -> PeriodTotals {
            Self.totals(of: completed, endingFrom: start, to: end, calendar: calendar)
        }

        lifetime = totals(from: .distantPast, to: .distantFuture)
        thisWeek = totals(from: week.start, to: week.end)
        thisMonth = totals(from: month.start, to: month.end)
        thisYear = totals(from: year.start, to: year.end)

        // `date(byAdding:)` clamps to the end of shorter months, so Mar 31
        // compares with Feb 28 (or 29).
        let monthAgo = calendar.date(byAdding: .month, value: -1, to: now) ?? now
        let lastMonthStart = calendar.dateInterval(of: .month, for: monthAgo)?.start ?? monthAgo
        lastMonthToDate = totals(from: lastMonthStart, to: monthAgo)

        let yearAgo = calendar.date(byAdding: .year, value: -1, to: now) ?? now
        let lastYearStart = calendar.dateInterval(of: .year, for: yearAgo)?.start ?? yearAgo
        lastYearToDate = totals(from: lastYearStart, to: yearAgo)

        daysElapsedInWeek = Self.dayCount(from: week.start, through: today, calendar: calendar)
        daysElapsedInMonth = Self.dayCount(from: month.start, through: today, calendar: calendar)
        daysElapsedInYear = Self.dayCount(from: year.start, through: today, calendar: calendar)
    }

    /// Totals for completed fasts that ended at or after `start` and before `end`.
    private static func totals(
        of sessions: [FastingSession],
        endingFrom start: Date,
        to end: Date,
        calendar: Calendar
    ) -> PeriodTotals {
        var result = PeriodTotals()
        var days = Set<Date>()
        for session in sessions {
            guard let ended = session.end, ended >= start, ended < end else { continue }
            result.fasts += 1
            result.hours += session.hours()
            days.insert(calendar.startOfDay(for: ended))
        }
        result.days = days.count
        return result
    }

    /// Number of calendar days from `start` through `day`, inclusive.
    private static func dayCount(from start: Date, through day: Date, calendar: Calendar) -> Int {
        let start = calendar.startOfDay(for: start)
        return max(1, (calendar.dateComponents([.day], from: start, to: day).day ?? 0) + 1)
    }
}

/// How a number compares with the same point in the previous period.
struct Trend: Equatable, Sendable {
    enum Direction: Sendable { case up, down, flat }

    let delta: Double

    /// Returns `nil` when both values are zero, since there's nothing to compare.
    /// Differences that round to zero at the displayed precision count as flat.
    init?(current: Double, previous: Double) {
        guard current != 0 || previous != 0 else { return nil }
        let rounded = (current - previous).rounded()
        delta = rounded == 0 ? 0 : rounded
    }

    var direction: Direction {
        delta > 0 ? .up : delta < 0 ? .down : .flat
    }
}
