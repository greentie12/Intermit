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

    private static let fastGoalIdentifier = "fast-goal"

    /// Schedules a "goal reached" notification for the fast in progress, if
    /// the user has turned notifications on in Profile.
    static func scheduleFastGoal(at date: Date, planName: String) {
        guard UserDefaults.standard.bool(forKey: storageKey), date > .now else { return }

        let content = UNMutableNotificationContent()
        content.title = String(localized: "Fasting Goal Reached")
        content.body = String(localized: "You've completed your \(planName) fast. End it in Intermit when you eat.")
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: date.timeIntervalSinceNow, repeats: false)
        let request = UNNotificationRequest(identifier: fastGoalIdentifier, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    /// Cancels the "goal reached" notification, e.g. when a fast ends early.
    static func cancelFastGoal() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [fastGoalIdentifier])
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
