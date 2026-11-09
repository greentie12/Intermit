import SwiftUI

/// The user's preferred look for the app: follow the device, or force light or dark.
enum AppearanceMode: String, CaseIterable, Identifiable {
    case system, light, dark

    /// Key used to remember the user's choice in `@AppStorage`.
    static let storageKey = "appearanceMode"

    var id: Self { self }

    var title: LocalizedStringResource {
        switch self {
        case .system: "System"
        case .light: "Light"
        case .dark: "Dark"
        }
    }

    /// The color scheme to force, or `nil` to follow the device setting.
    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}
