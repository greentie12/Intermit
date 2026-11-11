import Foundation

/// How a weekly low-calorie plan picks its fast days.
enum WeeklyRule: Equatable, Sendable {
    /// The user picks `count` days of the week, never two in a row.
    case weekdays(count: Int)
    /// Every other day, counting from a chosen first fast day.
    case alternating
}

/// How much to eat on a fast day.
enum FastDayTarget: Equatable, Sendable {
    /// A fixed calorie range, e.g. 500–600 for 5:2.
    case calories(ClosedRange<Int>)
    /// A share of the user's usual daily intake, e.g. 0.2 for 4:3.
    case shareOfUsualIntake(Double)

    /// e.g. "About 500–600 calories" or "About 20% of your usual intake (≈ 400 calories)".
    func description(usualCalories: Int?) -> String {
        switch self {
        case .calories(let range):
            return String(localized: "About \(range.lowerBound)–\(range.upperBound) calories")
        case .shareOfUsualIntake(let share):
            let percent = share.formatted(.percent.precision(.fractionLength(0)))
            guard let usualCalories else {
                return String(localized: "About \(percent) of your usual intake")
            }
            let calories = Int((Double(usualCalories) * share / 50).rounded() * 50) // nearest 50
            // Non-breaking space keeps "≈ 400" together when the line wraps.
            return String(localized: "About \(percent) of your usual intake (≈\u{00A0}\(calories) calories)")
        }
    }

    var usesUsualIntake: Bool {
        if case .shareOfUsualIntake = self { true } else { false }
    }
}

/// The user's fast days for a weekly plan.
struct WeeklySchedule: Codable, Equatable, Sendable {
    /// The `PlanGuide` this schedule belongs to.
    var planID: String
    /// Calendar weekday numbers (1 = Sunday … 7 = Saturday), for 5:2 and 4:3.
    var fastWeekdays: Set<Int> = []
    /// For alternate-day fasting: the first fast day. Every second day after
    /// it is also a fast day; days before it are normal days.
    var alternateStart: Date? = nil
    /// The user's usual daily calories, used to turn a percentage target into
    /// a number. `nil` if they'd rather not say.
    var usualCalories: Int? = nil
    /// The day the schedule was set. Earlier days count as normal days, so
    /// setting up midweek doesn't show missed fast days.
    var startDate: Date? = nil

    func isFastDay(_ date: Date, calendar: Calendar) -> Bool {
        if let startDate, calendar.startOfDay(for: date) < calendar.startOfDay(for: startDate) {
            return false
        }
        if let alternateStart {
            let days = calendar.dateComponents(
                [.day],
                from: calendar.startOfDay(for: alternateStart),
                to: calendar.startOfDay(for: date)
            ).day ?? 0
            return days >= 0 && days.isMultiple(of: 2)
        }
        return fastWeekdays.contains(calendar.component(.weekday, from: date))
    }

    /// The first fast day after `date`, looking up to two weeks ahead.
    func nextFastDay(after date: Date, calendar: Calendar) -> Date? {
        var day = calendar.startOfDay(for: date)
        for _ in 0..<14 {
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { return nil }
            day = next
            if isFastDay(day, calendar: calendar) { return day }
        }
        return nil
    }

    /// Whether `weekdays` has exactly `count` days with none next to each
    /// other, including Saturday and Sunday across the weekend.
    static func isValid(weekdays: Set<Int>, count: Int) -> Bool {
        weekdays.count == count && weekdays.allSatisfy { !weekdays.contains($0 % 7 + 1) }
    }

    /// Converts a plan's example days (0 = Monday) to calendar weekdays.
    static func calendarWeekdays(fromMondayIndexes indexes: [Int]) -> Set<Int> {
        Set(indexes.map { ($0 + 1) % 7 + 1 })
    }
}

/// The user's check-in for one fast day.
struct FastDayLog: Identifiable, Codable, Hashable, Sendable {
    enum Outcome: String, Codable, Sendable {
        /// Stayed near the fast-day target.
        case completed
        /// Ate more than planned or skipped the fast day.
        case skipped
    }

    enum Feeling: String, Codable, CaseIterable, Sendable {
        case good, hard, unwell

        var title: LocalizedStringResource {
            switch self {
            case .good: "Good"
            case .hard: "Hard"
            case .unwell: "Unwell"
            }
        }
    }

    var id = UUID()
    /// The start of the fast day, in the user's calendar.
    let day: Date
    let planID: String
    var outcome: Outcome
    var feeling: Feeling?
}
