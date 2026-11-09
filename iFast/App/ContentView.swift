import SwiftUI

/// The app's root view: a tab bar with one tab per main section.
struct ContentView: View {
    var body: some View {
        TabView {
            Tab("Home", systemImage: "house") {
                HomeView()
            }

            Tab("Plans", systemImage: "list.bullet.clipboard") {
                PlansView()
            }

            Tab("Info", systemImage: "info.circle") {
                InfoView()
            }

            Tab("Track", systemImage: "chart.line.uptrend.xyaxis") {
                TrackView()
            }

            Tab("Profile", systemImage: "person") {
                ProfileView()
            }
        }
        .tint(.accentColor)
    }
}

#Preview {
    ContentView()
}
