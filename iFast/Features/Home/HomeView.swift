import SwiftUI

struct HomeView: View {
    /// The user's current fasting plan, or `nil` if they haven't started one.
    var activePlan: FastingPlan? = nil

    /// Called when the profile button in the header is tapped.
    var onProfileTap: () -> Void = {}

    /// Called when the stats tile is tapped.
    var onStatsTap: () -> Void = {}

    /// Called when the body benefits tile is tapped.
    var onBenefitsTap: () -> Void = {}

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    HomeHeader(onProfileTap: onProfileTap)

                    ActivePlanCard(plan: activePlan)

                    // Two half-width tiles sharing a row, kept the same height.
                    HStack(spacing: 12) {
                        StatsCard(action: onStatsTap)
                        BenefitsCard(action: onBenefitsTap)
                    }
                    .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            .background {
                // Light gray page with a soft brand-colored glow at the top.
                ZStack(alignment: .top) {
                    Color(.systemGroupedBackground)

                    LinearGradient(
                        colors: [Color.accentColor.opacity(0.18), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 360)
                }
                .ignoresSafeArea()
            }
            // The header provides the branding, so the bar itself stays hidden.
            .toolbarVisibility(.hidden, for: .navigationBar)
        }
    }
}

#Preview("No Plan") {
    HomeView()
}

#Preview("Active Plan") {
    HomeView(activePlan: .sixteenEight)
}
