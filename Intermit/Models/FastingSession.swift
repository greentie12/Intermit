import Foundation

/// A single fast, from when the user started it to when they ended it.
struct FastingSession: Identifiable, Hashable, Sendable {
    let id: UUID
    let start: Date
    /// `nil` while the fast is still in progress.
    var end: Date?

    init(id: UUID = UUID(), start: Date, end: Date? = nil) {
        self.id = id
        self.start = start
        self.end = end
    }

    var isOngoing: Bool { end == nil }

    /// Length of the fast in hours, measured up to `now` if it hasn't ended.
    func hours(at now: Date = .now) -> Double {
        max(0, (end ?? now).timeIntervalSince(start)) / 3600
    }
}

extension FastingSession {
    /// About 14 months of made-up history ending yesterday, plus an optional fast
    /// in progress. Used for previews and as placeholder data until fasts are saved.
    static func samples(
        endingAt now: Date = .now,
        calendar: Calendar = .current,
        includeOngoing: Bool = true
    ) -> [FastingSession] {
        let today = calendar.startOfDay(for: now)
        var sessions: [FastingSession] = []

        for daysAgo in stride(from: 420, through: 1, by: -1) {
            // Skip some days, more often further back, so recent trends point up.
            if daysAgo % 4 == 0 || (daysAgo > 200 && daysAgo % 3 == 0) { continue }

            guard let day = calendar.date(byAdding: .day, value: -daysAgo, to: today),
                  let end = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: day)
            else { continue }

            let hours = 14 + Double(daysAgo % 7) // 14–20 hours
            sessions.append(FastingSession(start: end.addingTimeInterval(-hours * 3600), end: end))
        }

        if includeOngoing {
            sessions.append(FastingSession(start: now.addingTimeInterval(-5.25 * 3600)))
        }
        return sessions
    }
}
