import SwiftUI

/// The app's main sections, one per tab.
enum AppTab: Hashable {
    case home, plans, info, track, profile
}

/// The app's root view: a tab bar with one tab per main section.
struct ContentView: View {
    @State private var selectedTab: AppTab = .home
    @AppStorage(AppearanceMode.storageKey) private var appearance: AppearanceMode = .system
    @Environment(FastingStore.self) private var fastingStore
    @Environment(\.scenePhase) private var scenePhase

    @AppStorage(NotificationService.storageKey) private var notificationsEnabled = false
    @AppStorage(NotificationService.phaseStorageKey) private var phaseNotificationsEnabled = true
    @AppStorage(NotificationService.goalStorageKey) private var goalNotificationsEnabled = true

    /// Everything that affects which fast alerts should be scheduled.
    private struct NotificationSyncKey: Equatable {
        var fastID: UUID?
        var enabled: Bool
        var phases: Bool
        var goal: Bool
        var isActive: Bool
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Home", systemImage: "house", value: .home) {
                HomeView(
                    onProfileTap: { selectedTab = .profile },
                    onStatsTap: { selectedTab = .track },
                    onBenefitsTap: { selectedTab = .info },
                    onChoosePlan: { selectedTab = .plans }
                )
            }

            Tab("Plans", systemImage: "list.bullet.clipboard", value: .plans) {
                PlansView()
            }

            Tab("Info", systemImage: "info.circle", value: .info) {
                InfoView()
            }

            Tab("Track", systemImage: "chart.line.uptrend.xyaxis", value: .track) {
                TrackView(sessions: fastingStore.sessions)
            }

            Tab("Profile", systemImage: "person", value: .profile) {
                ProfileView()
            }
        }
        .tint(.accentColor)
        // Applies the Light/Dark/System choice from the Profile tab.
        .preferredColorScheme(appearance.colorScheme)
        // Keep phase and goal alerts in step with the fast in progress and the
        // settings in Profile, including after relaunch or a change in the
        // Settings app.
        .task(id: NotificationSyncKey(
            fastID: fastingStore.current?.id,
            enabled: notificationsEnabled,
            phases: phaseNotificationsEnabled,
            goal: goalNotificationsEnabled,
            isActive: scenePhase == .active
        )) {
            await NotificationService.syncFastNotifications(for: fastingStore.current)
        }
    }
}

#Preview {
    ContentView()
        .environment(FastingStore.preview())
}
