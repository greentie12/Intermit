import Foundation

/// Lifetime totals for the user's completed fasts.
struct FastingStats {
    var streakDays: Int
    var totalFasts: Int
    var longestHours: Int
    var averageHours: Int
}

extension FastingStats {
    static let sample = FastingStats(streakDays: 5, totalFasts: 23, longestHours: 20, averageHours: 16)
    static let empty = FastingStats(streakDays: 0, totalFasts: 0, longestHours: 0, averageHours: 0)
}
