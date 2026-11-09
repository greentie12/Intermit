import Foundation

/// A fasting schedule, such as 16:8 (16 hours fasting, 8 hours eating).
struct FastingPlan {
    let name: String
    let fastingHours: Int
    let eatingHours: Int
}

extension FastingPlan {
    static let sixteenEight = FastingPlan(name: "16:8", fastingHours: 16, eatingHours: 8)
}
