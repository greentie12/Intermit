import SwiftUI

struct HomeView: View {
    /// The user's current fasting plan, or `nil` if they haven't started one.
    var activePlan: FastingPlan? = nil

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    ActivePlanCard(plan: activePlan)
                        .padding(.horizontal)

                    Spacer(minLength: 0)
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Intermit")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

#Preview("No Plan") {
    HomeView()
}

#Preview("Active Plan") {
    HomeView(activePlan: .sixteenEight)
}
