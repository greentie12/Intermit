import Foundation

/// What the widget shows, written by the app whenever the user's plan or fast
/// changes and read by the widget extension.
///
/// The app resolves everything (names, phase titles, fast days) ahead of time,
/// so the widget doesn't need the app's models. This file is compiled into
/// both targets, so keep it free of app-only types.
nonisolated struct WidgetSnapshot: Codable, Equatable, Sendable {
    /// The user's chosen plan, e.g. "16:8". `nil` if they haven't picked one.
    var planName: String?
    /// A short description of the plan, e.g. "Fast 16 h, eat within 8 h, daily".
    var planSummary: String?
    /// Whether the plan is a weekly low-calorie plan rather than a timed fast.
    var isWeeklyPlan = false
    /// The fast in progress, if any.
    var fast: Fast?
    /// For weekly plans (5:2, 4:3, alternate-day): upcoming fast days.
    var weekly: Weekly?

    nonisolated struct Fast: Codable, Equatable, Sendable {
        var start: Date
        var goalHours: Double
        /// Every phase the fast passes through, in order, including the first.
        var phases: [Phase]

        var goalDate: Date { start.addingTimeInterval(goalHours * 3600) }

        /// The phase reached by `date`.
        func phase(at date: Date) -> Phase? {
            let hours = date.timeIntervalSince(start) / 3600
            return phases.last { $0.startHour <= hours } ?? phases.first
        }

        /// Fraction of the goal completed by `date`, from 0 to 1.
        func progress(at date: Date) -> Double {
            guard goalHours > 0 else { return 0 }
            return min(1, max(0, date.timeIntervalSince(start) / (goalHours * 3600)))
        }
    }

    nonisolated struct Phase: Codable, Equatable, Sendable {
        var startHour: Double
        var title: String
        var systemImage: String
    }

    nonisolated struct Weekly: Codable, Equatable, Sendable {
        /// Start-of-day dates for the next couple of weeks that are fast days.
        var fastDays: [Date]
        /// e.g. "About 500–600 calories".
        var targetText: String
        /// Whether today's fast day has been checked in, as of when this was written.
        var checkedInDays: [Date]

        func isFastDay(_ date: Date, calendar: Calendar) -> Bool {
            fastDays.contains { calendar.isDate($0, inSameDayAs: date) }
        }

        func isCheckedIn(_ date: Date, calendar: Calendar) -> Bool {
            checkedInDays.contains { calendar.isDate($0, inSameDayAs: date) }
        }

        func nextFastDay(after date: Date, calendar: Calendar) -> Date? {
            let startOfTomorrow = calendar.startOfDay(for: date).addingTimeInterval(24 * 3600)
            return fastDays.filter { $0 >= startOfTomorrow }.min()
        }
    }
}

nonisolated extension WidgetSnapshot {
    /// The App Group both the app and the widget can read and write.
    /// Must match the `com.apple.security.application-groups` entitlement.
    static let appGroupID = "group.devplaceholder.O7I3C5WS.Intermit"

    /// The `WidgetKit` kind for the Intermit widget.
    static let widgetKind = "IntermitWidget"

    private static let storageKey = "widgetSnapshot"

    private static var defaults: UserDefaults? { UserDefaults(suiteName: appGroupID) }

    /// The last snapshot the app saved, or an empty one.
    static func load() -> WidgetSnapshot {
        guard let data = defaults?.data(forKey: storageKey),
              let snapshot = try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
        else { return WidgetSnapshot() }
        return snapshot
    }

    func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        Self.defaults?.set(data, forKey: Self.storageKey)
    }
}
