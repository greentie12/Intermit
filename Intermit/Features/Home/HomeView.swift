import SwiftUI

struct HomeView: View {
    /// Called when the profile button in the header is tapped.
    var onProfileTap: () -> Void = {}

    /// Called when the stats tile is tapped.
    var onStatsTap: () -> Void = {}

    /// Called when the body benefits tile is tapped.
    var onBenefitsTap: () -> Void = {}

    /// Called when the user needs to pick a plan before fasting.
    var onChoosePlan: () -> Void = {}

    @Environment(FastingStore.self) private var store
    @State private var showingFast = false

    /// Lifetime totals for the stats tile.
    private var lifetime: PeriodTotals {
        TrackMetrics(sessions: store.sessions).lifetime
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    HomeHeader(onProfileTap: onProfileTap)

                    ActivePlanCard(
                        onChoosePlan: onChoosePlan,
                        onOpenFast: { showingFast = true }
                    )

                    // Two half-width tiles sharing a row, kept the same height.
                    HStack(spacing: 12) {
                        StatsCard(
                            totalHours: Int(lifetime.hours.rounded()),
                            totalDays: lifetime.days,
                            action: onStatsTap
                        )
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
            .sheet(isPresented: $showingFast) {
                ActiveFastView()
            }
        }
    }
}

#Preview("Not Fasting") {
    HomeView()
        .environment(FastingStore.preview())
}

#Preview("Fasting") {
    HomeView()
        .environment(FastingStore.preview([
            FastingSession(start: .now.addingTimeInterval(-9.5 * 3600), planID: "16-8", goalHours: 16),
        ]))
}
