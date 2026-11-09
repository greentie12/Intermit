import SwiftUI

/// The app's main sections, one per tab.
enum AppTab: Hashable {
    case home, plans, info, track, profile
}

/// The app's root view: a tab bar with one tab per main section.
struct ContentView: View {
    @State private var selectedTab: AppTab = .home
    @AppStorage(AppearanceMode.storageKey) private var appearance: AppearanceMode = .system

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Home", systemImage: "house", value: .home) {
                HomeView(
                    onProfileTap: { selectedTab = .profile },
                    onStatsTap: { selectedTab = .track },
                    onBenefitsTap: { selectedTab = .info }
                )
            }

            Tab("Plans", systemImage: "list.bullet.clipboard", value: .plans) {
                PlansView()
            }

            Tab("Info", systemImage: "info.circle", value: .info) {
                InfoView()
            }

            Tab("Track", systemImage: "chart.line.uptrend.xyaxis", value: .track) {
                TrackView()
            }

            Tab("Profile", systemImage: "person", value: .profile) {
                ProfileView()
            }
        }
        .tint(.accentColor)
        // Applies the Light/Dark/System choice from the Profile tab.
        .preferredColorScheme(appearance.colorScheme)
    }
}

#Preview {
    ContentView()
}
