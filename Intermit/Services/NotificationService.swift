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
