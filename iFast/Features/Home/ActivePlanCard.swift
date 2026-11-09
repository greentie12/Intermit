import SwiftUI

/// Card at the top of the Home page showing the user's active fasting plan,
/// or a prompt to get started if they haven't chosen one yet.
struct ActivePlanCard: View {
    let plan: FastingPlan?

    // Simple local session state for demo; later move to a view model if needed.
    @State private var isFasting = false
    @State private var startDate: Date? = nil
    @State private var endDate: Date? = nil

    private var totalSeconds: Double {
        guard let plan else { return 0 }
        return Double(plan.fastingHours) * 3600
    }

    private var remainingSeconds: Double {
        guard let endDate, isFasting else { return 0 }
        return max(0, endDate.timeIntervalSinceNow)
    }

    private var progress: Double {
        guard totalSeconds > 0, isFasting else { return 0 }
        let elapsed = totalSeconds - remainingSeconds
        return max(0, min(1, elapsed / totalSeconds))
    }

    private var timeString: String {
        guard isFasting else { return "" }
        let remaining = Int(remainingSeconds)
        let hours = remaining / 3600
        let minutes = (remaining % 3600) / 60
        let seconds = remaining % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }

    var body: some View {
        // Update the time every second when fasting.
        TimelineView(.periodic(from: .now, by: 1)) { _ in
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(plan == nil ? "Begin Here" : "Active Plan")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Text(plan?.name ?? "Start Fasting")
                            .font(.title)
                            .bold()

                        Text(planText)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    // Fitting icon
                    Image(systemName: isFasting ? "timer" : "flame")
                        .symbolRenderingMode(.hierarchical)
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(Color.accentColor.opacity(0.9))
                        .padding(10)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                if isFasting {
                    // Progress ring + time remaining
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .stroke(.quaternary, lineWidth: 10)

                            Circle()
                                .trim(from: 0, to: progress)
                                .stroke(
                                    AngularGradient(
                                        gradient: Gradient(colors: [
                                            .accentColor.opacity(0.85),
                                            .accentColor
                                        ]),
                                        center: .center
                                    ),
                                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                                )
                                .rotationEffect(.degrees(-90))

                            Text(timeString)
                                .font(.headline)
                                .monospacedDigit()
                                .contentTransition(.numericText())
                        }
                        .frame(width: 96, height: 96)

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Time remaining")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            ProgressView(value: progress)
                                .tint(.accentColor)

                            Text("\(Int(progress * 100))% complete")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }

                        Spacer()
                    }
                    .transition(.opacity.combined(with: .scale))
                } else {
                    // Start button with modern Liquid Glass look
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                            startSession()
                        }
                    } label: {
                        Label("Start Fasting", systemImage: "timer")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.glassProminent)
                    .tint(.accentColor)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            // Soft brand-colored gradient background
            .background(
                LinearGradient(
                    colors: [
                        .accentColor.opacity(0.12),
                        .accentColor.opacity(0.04)
                    ],
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
                // Subtle stroke for definition
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(.white.opacity(0.25), lineWidth: 0.5)
            }
            .shadow(color: .black.opacity(0.08), radius: 16, y: 8)
            .animation(.spring(response: 0.35, dampingFraction: 0.9), value: isFasting)
            // Attached to the card (not the Start button) because the button
            // leaves the screen as soon as the fast begins.
            .sensoryFeedback(.success, trigger: isFasting)
        }
    }

    private var planText: String {
        if let plan {
            return "\(plan.fastingHours) hours fasting · \(plan.eatingHours) hours eating"
        } else {
            return "Choose a fasting plan to get started."
        }
    }

    private func startSession() {
        guard let plan else { return }
        isFasting = true
        startDate = Date()
        endDate = Date().addingTimeInterval(Double(plan.fastingHours) * 3600)
    }
}

#Preview("No Plan") {
    ActivePlanCard(plan: nil)
        .padding()
}

#Preview("Active Plan") {
    ActivePlanCard(plan: .sixteenEight)
        .padding()
}
