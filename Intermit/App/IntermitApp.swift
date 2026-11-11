import SwiftUI

@main
struct IntermitApp: App {
    /// The user's fasts, shared by Home, Track, and Profile.
    @State private var fastingStore = FastingStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(fastingStore)
                .fontDesign(.rounded) // Global rounded font
        }
    }
}
