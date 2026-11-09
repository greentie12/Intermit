import Foundation

/// External web pages linked from Settings. Leave a link `nil` to show the
/// in-app placeholder page instead; set it to open the page in Safari.
enum AppLinks {
    static let privacyPolicy: URL? = nil
    static let termsOfUse: URL? = nil
    static let support: URL? = nil
}

extension Bundle {
    /// The app's version and build number for display, e.g. "1.0 (1)".
    var versionDisplay: String {
        let version = infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
        let build = infoDictionary?["CFBundleVersion"] as? String ?? "—"
        return "\(version) (\(build))"
    }
}
