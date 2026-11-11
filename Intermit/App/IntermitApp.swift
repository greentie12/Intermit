import SwiftUI
import UserNotifications

@main
struct IntermitApp: App {
    /// The user's fasts, shared by Home, Track, and Profile.
    @State private var fastingStore = FastingStore()

    init() {
        // Show fast alerts as banners even while the app is open.
        UNUserNotificationCenter.current().delegate = NotificationService.foregroundPresenter
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(fastingStore)
                .fontDesign(.rounded) // Global rounded font
        }
    }
}
