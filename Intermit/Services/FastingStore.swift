import Foundation
import Observation
import os

/// Owns the user's fasts: the one in progress, if any, and their history.
///
/// Fasts are saved to a small JSON file in Application Support after every
/// change, so a fast in progress keeps running if the app is closed or the
/// phone restarts.
@MainActor
@Observable
final class FastingStore {
    /// Every fast, oldest first. At most one is in progress.
    private(set) var sessions: [FastingSession] = []

    /// The fast in progress, if any.
    var current: FastingSession? {
        sessions.last(where: \.isOngoing)
    }

    /// Fast days for the user's weekly plan (5:2, 4:3, or alternate-day).
    private(set) var weeklySchedule: WeeklySchedule?
    /// Check-ins for weekly-plan fast days, oldest first.
    private(set) var fastDayLogs: [FastDayLog] = []

    /// `nil` keeps everything in memory, for previews.
    private let fileURL: URL?
    private static let logger = Logger(subsystem: "Intermit", category: "FastingStore")

    /// Weekly-plan data lives in a second file next to the fasts.
    private var weeklyFileURL: URL? {
        fileURL?.deletingLastPathComponent().appending(path: "fast-days.json")
    }

    /// What's saved in `weeklyFileURL`.
    private struct WeeklyData: Codable {
        var schedule: WeeklySchedule?
        var logs: [FastDayLog]
    }

    init(fileURL: URL? = FastingStore.defaultFileURL) {
        self.fileURL = fileURL
        sessions = Self.load([FastingSession].self, from: fileURL) ?? []
        let weekly = Self.load(WeeklyData.self, from: weeklyFileURL)
        weeklySchedule = weekly?.schedule
        fastDayLogs = weekly?.logs ?? []
    }

    nonisolated static var defaultFileURL: URL {
        URL.applicationSupportDirectory.appending(path: "fasts.json")
    }

    /// An in-memory store with the given data, for previews.
    static func preview(
        _ sessions: [FastingSession] = [],
        weeklySchedule: WeeklySchedule? = nil,
        fastDayLogs: [FastDayLog] = []
    ) -> FastingStore {
        let store = FastingStore(fileURL: nil)
        store.sessions = sessions
        store.weeklySchedule = weeklySchedule
        store.fastDayLogs = fastDayLogs
        return store
    }

    // MARK: Actions

    /// Starts a fast toward `goalHours`, unless one is already running.
    func startFast(planID: String, goalHours: Double, at date: Date = .now) {
        guard current == nil else { return }
        sessions.append(FastingSession(start: date, planID: planID, goalHours: goalHours))
        save()
    }

    /// Ends the fast in progress and keeps it in the history.
    func endFast(at date: Date = .now) {
        guard let index = sessions.lastIndex(where: \.isOngoing) else { return }
        sessions[index].end = max(date, sessions[index].start)
        save()
    }

    /// Removes the fast in progress without saving it, e.g. if it was started
    /// by mistake.
    func discardFast() {
        guard let index = sessions.lastIndex(where: \.isOngoing) else { return }
        sessions.remove(at: index)
        save()
    }

    // MARK: Weekly plans

    /// Saves the user's fast days for a weekly plan, replacing any earlier ones.
    func setWeeklySchedule(_ schedule: WeeklySchedule) {
        weeklySchedule = schedule
        saveWeekly()
    }

    /// The check-in for the fast day containing `date`, if any.
    func fastDayLog(on date: Date, calendar: Calendar = .current) -> FastDayLog? {
        fastDayLogs.last { calendar.isDate($0.day, inSameDayAs: date) }
    }

    /// Records how a fast day went, replacing any earlier check-in that day.
    func logFastDay(
        on date: Date,
        planID: String,
        outcome: FastDayLog.Outcome,
        feeling: FastDayLog.Feeling?,
        calendar: Calendar = .current
    ) {
        fastDayLogs.removeAll { calendar.isDate($0.day, inSameDayAs: date) }
        fastDayLogs.append(FastDayLog(
            day: calendar.startOfDay(for: date),
            planID: planID,
            outcome: outcome,
            feeling: feeling
        ))
        saveWeekly()
    }

    // MARK: Persistence

    private static func load<Value: Decodable>(_ type: Value.Type, from url: URL?) -> Value? {
        guard let url, FileManager.default.fileExists(atPath: url.path()) else { return nil }
        do {
            return try JSONDecoder().decode(type, from: Data(contentsOf: url))
        } catch {
            logger.error("Couldn't load \(url.lastPathComponent): \(error.localizedDescription)")
            return nil
        }
    }

    private func save() {
        write(sessions, to: fileURL)
    }

    private func saveWeekly() {
        write(WeeklyData(schedule: weeklySchedule, logs: fastDayLogs), to: weeklyFileURL)
    }

    private func write(_ value: some Encodable, to url: URL?) {
        guard let url else { return }
        do {
            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try JSONEncoder().encode(value).write(to: url, options: .atomic)
        } catch {
            Self.logger.error("Couldn't save \(url.lastPathComponent): \(error.localizedDescription)")
        }
    }
}
