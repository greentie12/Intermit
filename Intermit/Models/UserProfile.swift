import Foundation

/// Basic information about the signed-in user.
struct UserProfile {
    var name: String
    var isPro: Bool

    /// Up to two initials from the user's name, e.g. "Alex Rivera" → "AR".
    var initials: String {
        name.split(separator: " ")
            .prefix(2)
            .compactMap(\.first)
            .map(String.init)
            .joined()
            .uppercased()
    }
}

extension UserProfile {
    static let samplePro = UserProfile(name: "Alex Rivera", isPro: true)
    static let sampleFree = UserProfile(name: "Alex Rivera", isPro: false)
}
