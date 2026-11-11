import SwiftUI

// MARK: - Progress

/// Everything the live fast screens show, worked out for one moment in time.
@MainActor
struct FastProgress {
    let fast: FastingSession
    let now: Date

    var planName: String {
        fast.planID.flatMap(PlanGuide.plan(withID:))?.name ?? String(localized: "Fast")
    }

    var elapsed: TimeInterval { max(0, now.timeIntervalSince(fast.start)) }
    var elapsedHours: Double { elapsed / 3600 }

    var goalHours: Double { fast.goalHours ?? 16 }
    var goalDate: Date { fast.start.addingTimeInterval(goalHours * 3600) }
    var remaining: TimeInterval { max(0, goalDate.timeIntervalSince(now)) }

    var fraction: Double { min(1, elapsed / (goalHours * 3600)) }
    var isGoalReached: Bool { elapsed >= goalHours * 3600 }

    /// The body stage reached so far.
    var stage: FastingStage { FastingStage.stage(atHours: elapsedHours) }

    /// The next stage, if it starts before the goal.
    var nextStageWithinGoal: FastingStage? {
        guard let next = stage.next, Double(next.startHour) < goalHours else { return nil }
        return next
    }

    /// e.g. "13:24:05".
    var elapsedClock: String {
        Duration.seconds(elapsed).formatted(.time(pattern: .hourMinuteSecond))
    }

    /// e.g. "2 hr, 36 min".
    var remainingText: String {
        Self.shortDuration(remaining)
    }

    /// e.g. "16" or "15.5".
    var goalHoursText: String {
        goalHours.formatted(.number.precision(.fractionLength(0...1)))
    }

    var accessibilitySummary: String {
        let elapsedText = Duration.seconds(elapsed).formatted(.units(allowed: [.hours, .minutes], width: .wide))
        let status = isGoalReached
            ? String(localized: "goal reached")
            : String(localized: "\(Duration.seconds(remaining).formatted(.units(allowed: [.hours, .minutes], width: .wide))) to go")
        return String(localized: "\(elapsedText) elapsed, \(status). Current phase: \(String(localized: stage.title)).")
    }

    static func shortDuration(_ interval: TimeInterval) -> String {
        // Round up so "to go" never reads 0 min while time remains.
        let minutes = (interval / 60).rounded(.up)
        return Duration.seconds(minutes * 60).formatted(.units(allowed: [.hours, .minutes], width: .abbreviated))
    }
}

// MARK: - Ring

/// A circular progress ring with content in the middle.
struct FastProgressRing<Center: View>: View {
    let progress: Double
    var lineWidth: CGFloat = 10
    @ViewBuilder let center: Center

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.accentColor.opacity(0.15), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: max(0.001, progress))
                .stroke(
                    AngularGradient(
                        colors: [.accentColor.opacity(0.7), .accentColor],
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360 * max(0.001, progress))
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.6), value: progress)

            center
        }
    }
}

// MARK: - Detail screen

/// Opened from the Home card: the live clock, the current metabolic phase and
/// what it may mean for the body, what's next, and a button to end the fast.
struct ActiveFastView: View {
    @Environment(FastingStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var showingEndConfirmation = false

    var body: some View {
        NavigationStack {
            Group {
                if let fast = store.current {
                    TimelineView(.periodic(from: .now, by: 1)) { context in
                        content(FastProgress(fast: fast, now: context.date))
                    }
                } else {
                    ContentUnavailableView("No Fast in Progress", systemImage: "timer")
                }
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .safeAreaBar(edge: .bottom) {
                if store.current != nil {
                    endButton
                        .padding(.horizontal, 20)
                        .padding(.bottom, 8)
                }
            }
        }
    }

    private var navigationTitle: Text {
        if let fast = store.current {
            Text("\(FastProgress(fast: fast, now: .now).planName) Fast")
        } else {
            Text("Fast")
        }
    }

    // MARK: Content

    private func content(_ progress: FastProgress) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                hero(progress)
                currentPhase(progress)
                upNext(progress)
                timeline(progress)

                Text("Timing is approximate and varies from person to person. Stop fasting and eat if you feel dizzy, faint, or unwell.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 4)
            }
            .padding()
        }
        // The confirmation needs the current numbers, so it lives here.
        .confirmationDialog(
            "End your fast early?",
            isPresented: $showingEndConfirmation,
            titleVisibility: .visible
        ) {
            Button("End Fast") { endFast() }
            Button("Discard Fast", role: .destructive) { discardFast() }
            Button("Keep Fasting", role: .cancel) {}
        } message: {
            Text("You've fasted \(Duration.seconds(progress.elapsed).formatted(.units(allowed: [.hours, .minutes], width: .wide))) of your \(progress.goalHoursText)-hour goal. Ending saves it to your history; discarding removes it.")
        }
    }

    private func hero(_ progress: FastProgress) -> some View {
        VStack(spacing: 16) {
            FastProgressRing(progress: progress.fraction, lineWidth: 16) {
                VStack(spacing: 4) {
                    Text("Elapsed")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(progress.elapsedClock)
                        .font(.system(.largeTitle, design: .rounded))
                        .bold()
                        .monospacedDigit()
                        .contentTransition(.numericText())
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                    Text("Goal \(progress.goalHoursText) h")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.tint)
                }
                .padding(28)
            }
            .frame(width: 240, height: 240)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Fast progress")
            .accessibilityValue(progress.accessibilitySummary)

            if progress.isGoalReached {
                Label("You've reached your goal. End your fast when you're ready to eat.", systemImage: "checkmark.seal.fill")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.tint)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text("\(progress.remainingText) to go")
                    .font(.headline)
            }

            HStack {
                timeLabel("Started", date: progress.fast.start, now: progress.now)
                Spacer()
                timeLabel("Goal", date: progress.goalDate, now: progress.now, alignment: .trailing)
            }
        }
        .frame(maxWidth: .infinity)
        .planCard(padding: 20)
    }

    private func timeLabel(
        _ title: LocalizedStringResource,
        date: Date,
        now: Date,
        alignment: HorizontalAlignment = .leading
    ) -> some View {
        VStack(alignment: alignment, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            // Show the weekday too when it isn't today, e.g. "Tue 12:00 PM".
            Text(date, format: Calendar.current.isDate(date, inSameDayAs: now)
                 ? .dateTime.hour().minute()
                 : .dateTime.weekday(.abbreviated).hour().minute())
                .font(.subheadline)
                .fontWeight(.semibold)
                .monospacedDigit()
        }
        .accessibilityElement(children: .combine)
    }

    private func currentPhase(_ progress: FastProgress) -> some View {
        let stage = progress.stage
        return VStack(alignment: .leading, spacing: 12) {
            sectionLabel("Current Phase", systemImage: "waveform.path.ecg")

            HStack(spacing: 12) {
                StageIcon(stage: stage, state: .current)
                VStack(alignment: .leading, spacing: 2) {
                    Text(stageRange(stage, goalHours: progress.goalHours))
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.tint)
                    Text(stage.title)
                        .font(.title3)
                        .bold()
                }
            }

            Text(stage.detail)
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)

            Divider()

            sectionLabel("What It May Mean for You", systemImage: "heart.fill")
            Text(stage.benefit)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .planCard()
    }

    @ViewBuilder
    private func upNext(_ progress: FastProgress) -> some View {
        if !progress.isGoalReached {
            HStack(spacing: 12) {
                if let next = progress.nextStageWithinGoal {
                    StageIcon(stage: next, state: .upcoming)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Up Next")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(next.title)
                            .font(.headline)
                    }
                    Spacer(minLength: 8)
                    let untilNext = max(0, progress.fast.start.addingTimeInterval(Double(next.startHour) * 3600).timeIntervalSince(progress.now))
                    Text("in \(FastProgress.shortDuration(untilNext))")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .monospacedDigit()
                } else {
                    GoalIcon(isReached: false)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Up Next")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("Goal Reached")
                            .font(.headline)
                    }
                    Spacer(minLength: 8)
                    Text("in \(progress.remainingText)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .monospacedDigit()
                }
            }
            .planCard()
            .accessibilityElement(children: .combine)
        }
    }

    private func timeline(_ progress: FastProgress) -> some View {
        let stages = FastingStage.all.filter { Double($0.startHour) < progress.goalHours }
        return VStack(alignment: .leading, spacing: 12) {
            sectionLabel("Your Fast", systemImage: "clock.fill")

            VStack(alignment: .leading, spacing: 0) {
                ForEach(stages) { stage in
                    let state: StageIcon.Status = stage.id < progress.stage.id
                        ? .done
                        : (stage.id == progress.stage.id ? .current : .upcoming)
                    HStack(alignment: .top, spacing: 12) {
                        VStack(spacing: 0) {
                            StageIcon(stage: stage, state: state, size: 30)
                            Rectangle()
                                .fill(Color.accentColor.opacity(state == .upcoming ? 0.15 : 0.4))
                                .frame(width: 2)
                                .frame(maxHeight: .infinity)
                        }
                        VStack(alignment: .leading, spacing: 1) {
                            Text(stageRange(stage, goalHours: progress.goalHours))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                            Text(stage.title)
                                .font(.subheadline)
                                .fontWeight(state == .current ? .bold : .regular)
                                .foregroundStyle(state == .upcoming ? .secondary : .primary)
                        }
                        .padding(.top, 2)
                        .padding(.bottom, 12)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityValue(state.accessibilityText)
                }

                HStack(spacing: 12) {
                    GoalIcon(isReached: progress.isGoalReached, size: 30)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("\(progress.goalHoursText) h")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("Goal")
                            .font(.subheadline)
                            .fontWeight(progress.isGoalReached ? .bold : .regular)
                    }
                }
                .accessibilityElement(children: .combine)
            }
        }
        .planCard()
    }

    /// e.g. "12–16 h", capped at the goal, or "18+ h" past it.
    private func stageRange(_ stage: FastingStage, goalHours: Double) -> LocalizedStringResource {
        let goal = Int(goalHours.rounded(.up))
        if let next = stage.next, next.startHour <= goal {
            return "\(stage.startHour)–\(next.startHour) h"
        } else if stage.startHour < goal {
            return "\(stage.startHour)–\(goal) h"
        } else {
            return "\(stage.startHour)+ h"
        }
    }

    private func sectionLabel(_ title: LocalizedStringResource, systemImage: String) -> some View {
        Label {
            Text(title).textCase(.uppercase)
        } icon: {
            Image(systemName: systemImage)
        }
        .font(.caption)
        .fontWeight(.semibold)
        .foregroundStyle(.secondary)
        .accessibilityAddTraits(.isHeader)
    }

    // MARK: End

    @ViewBuilder
    private var endButton: some View {
        let reached = store.current.map { FastProgress(fast: $0, now: .now).isGoalReached } ?? false
        Button {
            if reached {
                endFast()
            } else {
                showingEndConfirmation = true
            }
        } label: {
            Label("End Fast", systemImage: "stop.fill")
                .frame(maxWidth: .infinity)
        }
        .controlSize(.large)
        .buttonStyle(.glassProminent)
    }

    private func endFast() {
        store.endFast()
        dismiss()
    }

    private func discardFast() {
        store.discardFast()
        dismiss()
    }
}

// MARK: - Icons

/// A stage's icon in a circle: filled when reached, outlined when upcoming.
private struct StageIcon: View {
    enum Status {
        case done, current, upcoming

        var accessibilityText: LocalizedStringResource {
            switch self {
            case .done: "Completed"
            case .current: "Current phase"
            case .upcoming: "Upcoming"
            }
        }
    }

    let stage: FastingStage
    let state: Status
    var size: CGFloat = 40

    @ScaledMetric(relativeTo: .body) private var scale = 1

    var body: some View {
        let side = size * scale
        Image(systemName: state == .done ? "checkmark" : stage.systemImage)
            .font(.system(size: side * 0.45, weight: .semibold))
            .foregroundStyle(state == .upcoming ? Color.accentColor : Color.white)
            .frame(width: side, height: side)
            .background(
                state == .upcoming ? Color.accentColor.opacity(0.15) : Color.accentColor.opacity(state == .done ? 0.6 : 1),
                in: Circle()
            )
            .accessibilityHidden(true)
    }
}

/// The checkered flag at the end of the timeline.
private struct GoalIcon: View {
    let isReached: Bool
    var size: CGFloat = 40

    @ScaledMetric(relativeTo: .body) private var scale = 1

    var body: some View {
        let side = size * scale
        Image(systemName: "flag.checkered")
            .font(.system(size: side * 0.45, weight: .semibold))
            .foregroundStyle(isReached ? Color.white : Color.accentColor)
            .frame(width: side, height: side)
            .background(isReached ? Color.accentColor : Color.accentColor.opacity(0.15), in: Circle())
            .accessibilityHidden(true)
    }
}

#Preview("13 h into 16:8") {
    ActiveFastView()
        .environment(FastingStore.preview([
            FastingSession(start: .now.addingTimeInterval(-13.4 * 3600), planID: "16-8", goalHours: 16),
        ]))
}

#Preview("Goal reached") {
    ActiveFastView()
        .environment(FastingStore.preview([
            FastingSession(start: .now.addingTimeInterval(-14.2 * 3600), planID: "14-10", goalHours: 14),
        ]))
}
