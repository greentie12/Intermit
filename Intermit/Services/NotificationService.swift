import Foundation
import UserNotifications
#if canImport(UIKit)
import UIKit
#endif

/// Handles the system permission for sending notifications.
enum NotificationService {
    /// Key used to remember the user's in-app notifications choice in `@AppStorage`.
    static let storageKey = "notificationsEnabled"

    /// Asks iOS for permission to send notifications. Shows the system prompt
    /// the first time; afterwards returns the user's existing answer.
    static func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        return (try? await center.requestAuthorization(options: [.alert, .badge, .sound])) ?? false
    }

    /// Whether the app is currently allowed to send notifications.
    static func isAuthorized() async -> Bool {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional:
            return true
        default:
            return false
        }
    }

    // MARK: Fast notifications

    /// `@AppStorage` key for alerts when a fast reaches a new metabolic phase.
    static let phaseStorageKey = "phaseNotificationsEnabled"
    /// `@AppStorage` key for the alert when a fast reaches its goal.
    static let goalStorageKey = "goalNotificationsEnabled"

    /// `@AppStorage` key remembering that the user was already asked to turn
    /// on notifications when starting a fast, so it's only asked once.
    static let askedAtFastStartStorageKey = "askedForNotificationsAtFastStart"

    private static let fastIdentifierPrefix = "fast-"
    private static let goalIdentifier = "fast-goal"

    /// Whether the user has turned on notifications, and each kind of fast
    /// alert. The per-kind settings default to on.
    static var isEnabled: Bool { UserDefaults.standard.bool(forKey: storageKey) }
    static var isPhaseEnabled: Bool { UserDefaults.standard.object(forKey: phaseStorageKey) as? Bool ?? true }
    static var isGoalEnabled: Bool { UserDefaults.standard.object(forKey: goalStorageKey) as? Bool ?? true }

    /// Makes the scheduled alerts match the fast in progress and the user's
    /// settings: clears every fast alert, then schedules the ones still ahead.
    /// Call it whenever a fast starts or ends, a setting changes, or the app
    /// becomes active.
    static func syncFastNotifications(for fast: FastingSession?, now: Date = .now) async {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
        center.removePendingNotificationRequests(
            withIdentifiers: pending.map(\.identifier).filter { $0.hasPrefix(fastIdentifierPrefix) }
        )

        guard isEnabled, let fast, fast.isOngoing, await isAuthorized() else { return }

        let planName = fast.planID.flatMap(PlanGuide.plan(withID:))?.name ?? String(localized: "Fast")
        let goalHours = fast.goalHours ?? 16

        if isPhaseEnabled {
            // One alert per phase the fast will reach before its goal (the
            // goal alert covers the end), skipping the first digesting stage.
            for stage in FastingStage.all where stage.startHour > 0 && Double(stage.startHour) < goalHours {
                let date = fast.start.addingTimeInterval(Double(stage.startHour) * 3600)
                guard date > now else { continue }

                let content = UNMutableNotificationContent()
                content.title = String(localized: stage.title)
                content.subtitle = String(localized: "\(planName) · \(stage.startHour) hours in")
                content.body = String(localized: stage.detail)
                content.sound = .default
                content.threadIdentifier = fast.id.uuidString

                await add(content, at: date, identifier: "\(fastIdentifierPrefix)phase-\(stage.id)", now: now)
            }
        }

        if isGoalEnabled {
            let date = fast.start.addingTimeInterval(goalHours * 3600)
            if date > now {
                let content = UNMutableNotificationContent()
                content.title = String(localized: "Fasting Goal Reached")
                // If a phase starts right at the goal (e.g. 12 h on 12:12),
                // mention it here instead of sending a second alert.
                if let stage = FastingStage.all.first(where: { Double($0.startHour) == goalHours }) {
                    content.body = String(localized: "You've completed your \(planName) fast and reached \(String(localized: stage.title)). End it in Intermit when you eat.")
                } else {
                    content.body = String(localized: "You've completed your \(planName) fast. End it in Intermit when you eat.")
                }
                content.sound = .default
                content.threadIdentifier = fast.id.uuidString

                await add(content, at: date, identifier: goalIdentifier, now: now)
            }
        }
    }

    private static func add(_ content: UNNotificationContent, at date: Date, identifier: String, now: Date) async {
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, date.timeIntervalSince(now)), repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        try? await UNUserNotificationCenter.current().add(request)
    }

    // MARK: Foreground

    /// Shows fast alerts as banners even while Intermit is open. Assigned as
    /// the notification center's delegate at launch.
    static let foregroundPresenter = ForegroundPresenter()

    final class ForegroundPresenter: NSObject, UNUserNotificationCenterDelegate {
        nonisolated func userNotificationCenter(
            _ center: UNUserNotificationCenter,
            willPresent notification: UNNotification
        ) async -> UNNotificationPresentationOptions {
            [.banner, .list, .sound]
        }
    }

    /// Cancels any notifications the app has scheduled.
    static func removeAllPending() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    /// The app's notification page in the Settings app.
    static var settingsURL: URL? {
        #if canImport(UIKit)
        URL(string: UIApplication.openNotificationSettingsURLString)
        #else
        nil
        #endif
    }
}
