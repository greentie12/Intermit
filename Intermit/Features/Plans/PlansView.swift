import SwiftUI

/// The plan catalog, split into Starter and Advanced. Tapping a plan opens
/// its summary, where the user can decide whether to start it.
struct PlansView: View {
    @AppStorage(PlanGuide.activePlanStorageKey) private var activePlanID = ""

    var body: some View {
        NavigationStack {
            List {
                Section {
                    planLinks(PlanGuide.starterPlans)
                } header: {
                    Text("Starter")
                } footer: {
                    Text("New to fasting? Start with 12:12, then move to 14:10 after 2–4 comfortable weeks.")
                }

                Section {
                    planLinks(PlanGuide.advancedPlans)
                } header: {
                    Text("Advanced")
                } footer: {
                    Text("Longer fasts and whole-day plans have less research behind them or are harder to stick with. Try them once you're comfortable with a Starter plan.")
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Plans")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private func planLinks(_ plans: [PlanGuide]) -> some View {
        ForEach(plans) { plan in
            NavigationLink {
                PlanDetailView(plan: plan)
            } label: {
                PlanRow(plan: plan, isActive: plan.id == activePlanID)
            }
        }
    }
}

#Preview {
    PlansView()
}
