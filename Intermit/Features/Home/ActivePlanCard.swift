import SwiftUI

/// Card at the top of the Home page. Shows the user's plan with a Start
/// Fasting button, or the fast in progress with a live clock. Tapping a fast
/// in progress opens its details.
struct ActivePlanCard: View {
    /// Called when the user needs to pick a plan first.
    var onChoosePlan: () -> Void = {}
    /// Called when the user taps a fast in progress.
    var onOpenFast: () -> Void = {}

    @Environment(FastingStore.self) private var store
    @AppStorage(PlanGuide.activePlanStorageKey) private var activePlanID = ""
    @AppStorage(PlanGuide.customHoursStorageKey) private var customHours = 16

    private var plan: PlanGuide? { PlanGuide.plan(withID: activePlanID) }

    var body: some View {
        Group {
            if let fast = store.current {
                Button(action: onOpenFast) {
                    FastInProgress(fast: fast)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityHint("Shows your current phase and what's happening in your body")
            } else if let plan, !plan.supportsTimedFasts {
                WeeklyPlanCardContent(plan: plan)
            } else {
                idleContent
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .modifier(ActivePlanCardBackground())
        .animation(.spring(response: 0.35, dampingFraction: 0.9), value: store.current?.id)
        // A success tap when a fast starts, and a lighter one when it ends.
        .sensoryFeedback(trigger: store.current?.id) { _, newValue in
            newValue != nil ? .success : .impact(weight: .medium)
        }
    }

    // MARK: Not fasting

    private var idleContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(plan == nil ? "Begin Here" : "Active Plan")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text(plan?.name ?? "Start Fasting")
                        .font(.title)
                        .bold()

                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Image(systemName: "flame")
                    .symbolRenderingMode(.hierarchical)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(Color.accentColor.opacity(0.9))
                    .padding(10)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .accessibilityHidden(true)
            }

            if let plan, plan.supportsTimedFasts {
                Button {
                    start(plan)
                } label: {
                    Label("Start Fasting", systemImage: "timer")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glassProminent)
                .tint(.accentColor)
            } else {
                Button(action: onChoosePlan) {
                    Label("Choose a Plan", systemImage: "list.bullet.clipboard")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glassProminent)
                .tint(.accentColor)
            }
        }
    }

    private var subtitle: LocalizedStringResource {
        guard let plan else { return "Choose a fasting plan to get started." }
        guard let goal = plan.goalHours(customHours: customHours) else {
            return plan.scheduleSummary
        }
        if case .custom = plan.schedule {
            return "Fast \(goal) h, eat within \(24 - goal) h, daily"
        }
        return plan.scheduleSummary
    }

    private func start(_ plan: PlanGuide) {
        guard let goal = plan.goalHours(customHours: customHours) else { return }
        let now = Date.now
        store.startFast(planID: plan.id, goalHours: Double(goal), at: now)
        NotificationService.scheduleFastGoal(at: now.addingTimeInterval(Double(goal) * 3600), planName: plan.name)
    }
}

// MARK: - Fasting

/// The card's content while fasting: a live clock, time left, progress ring,
/// and the current phase.
private struct FastInProgress: View {
    let fast: FastingSession

    var body: some View {
        // Ticks every second so the clock stays live.
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let progress = FastProgress(fast: fast, now: context.date)

            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .center, spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Fasting · \(progress.planName)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Text(progress.elapsedClock)
                            .font(.system(.largeTitle, design: .rounded))
                            .bold()
                            .monospacedDigit()
                            .contentTransition(.numericText())
                            .minimumScaleFactor(0.7)
                            .lineLimit(1)

                        Text(progress.isGoalReached
                             ? "Goal reached · \(progress.goalHoursText) h"
                             : "\(progress.remainingText) to go")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(progress.isGoalReached ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))
                    }

                    Spacer(minLength: 8)

                    FastProgressRing(progress: progress.fraction, lineWidth: 9) {
                        Image(systemName: progress.isGoalReached ? "checkmark" : progress.stage.systemImage)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundStyle(.tint)
                    }
                    .frame(width: 84, height: 84)
                    .accessibilityHidden(true)
                }

                HStack(spacing: 8) {
                    Image(systemName: progress.stage.systemImage)
                        .foregroundStyle(.tint)
                        .accessibilityHidden(true)
                    Text(progress.stage.title)
                        .fontWeight(.semibold)
                    Spacer(minLength: 8)
                    Text("Details")
                        .foregroundStyle(.secondary)
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.tertiary)
                        .accessibilityHidden(true)
                }
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.accentColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text("Fasting, \(progress.planName)"))
            .accessibilityValue(progress.accessibilitySummary)
        }
    }
}

// MARK: - Background

/// Soft brand-colored gradient on a raised surface, shared by every card state.
private struct ActivePlanCardBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                LinearGradient(
                    colors: [.accentColor.opacity(0.12), .accentColor.opacity(0.04)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 24, style: .continuous)
            )
            // Solid surface beneath the gradient: white in light mode,
            // an elevated gray in dark mode.
            .background(
                Color(.secondarySystemGroupedBackground),
                in: RoundedRectangle(cornerRadius: 24, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(.white.opacity(0.25), lineWidth: 0.5)
            }
            .shadow(color: .black.opacity(0.08), radius: 16, y: 8)
    }
}

#Preview("No Plan") {
    ActivePlanCard()
        .padding()
        .environment(FastingStore.preview())
}

#Preview("Fasting") {
    ActivePlanCard()
        .padding()
        .environment(FastingStore.preview([
            FastingSession(start: .now.addingTimeInterval(-13.4 * 3600), planID: "16-8", goalHours: 16),
        ]))
}
