import WidgetKit
import SwiftUI

extension Color {
    /// Intermit's teal, from the widget's asset catalog (matches the app's accent).
    static let brand = Color("AccentColor")
}

// MARK: - Timeline

struct FastEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> FastEntry {
        FastEntry(date: .now, snapshot: .sampleFasting)
    }

    func getSnapshot(in context: Context, completion: @escaping (FastEntry) -> Void) {
        // The widget gallery shows a sample; otherwise show the real state.
        let snapshot = context.isPreview ? .sampleFasting : WidgetSnapshot.load()
        completion(FastEntry(date: .now, snapshot: snapshot))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<FastEntry>) -> Void) {
        let snapshot = WidgetSnapshot.load()
        let now = Date.now
        let calendar = Calendar.current
        var dates: [Date] = [now]

        // The clock and progress bar tick on their own; new entries are only
        // needed when the text changes: each new phase and the goal.
        if let fast = snapshot.fast {
            dates += fast.phases.map { fast.start.addingTimeInterval($0.startHour * 3600) }
            dates.append(fast.goalDate)
        }

        // Weekly plans switch between fast and normal days at midnight.
        if snapshot.weekly != nil {
            let today = calendar.startOfDay(for: now)
            dates += (1...7).compactMap { calendar.date(byAdding: .day, value: $0, to: today) }
        }

        let entries = Set(dates.filter { $0 >= now })
            .sorted()
            .map { FastEntry(date: $0, snapshot: snapshot) }

        // The app reloads the widget whenever the plan or fast changes, so it
        // only needs to ask again after the last scheduled change.
        let policy: TimelineReloadPolicy = entries.count > 1 ? .atEnd : .never
        completion(Timeline(entries: entries, policy: policy))
    }
}

// MARK: - State

/// What to show, worked out from a snapshot at an entry's date.
enum WidgetState {
    case noPlan
    case ready(name: String, summary: String)
    case weeklyNeedsSetup(name: String)
    case weekly(name: String, isFastDay: Bool, isCheckedIn: Bool, target: String, nextFastDay: Date?)
    case fasting(name: String, fast: WidgetSnapshot.Fast, phase: WidgetSnapshot.Phase?, isGoalReached: Bool)

    init(snapshot: WidgetSnapshot, date: Date, calendar: Calendar = .current) {
        if let fast = snapshot.fast {
            self = .fasting(
                name: snapshot.planName ?? String(localized: "Fast"),
                fast: fast,
                phase: fast.phase(at: date),
                isGoalReached: date >= fast.goalDate
            )
        } else if let name = snapshot.planName {
            if snapshot.isWeeklyPlan {
                if let weekly = snapshot.weekly {
                    self = .weekly(
                        name: name,
                        isFastDay: weekly.isFastDay(date, calendar: calendar),
                        isCheckedIn: weekly.isCheckedIn(date, calendar: calendar),
                        target: weekly.targetText,
                        nextFastDay: weekly.nextFastDay(after: date, calendar: calendar)
                    )
                } else {
                    self = .weeklyNeedsSetup(name: name)
                }
            } else {
                self = .ready(name: name, summary: snapshot.planSummary ?? "")
            }
        } else {
            self = .noPlan
        }
    }
}

// MARK: - Entry view

struct IntermitWidgetEntryView: View {
    var entry: FastEntry

    @Environment(\.widgetFamily) private var family

    private var state: WidgetState { WidgetState(snapshot: entry.snapshot, date: entry.date) }

    var body: some View {
        Group {
            switch family {
            case .accessoryCircular: CircularView(state: state)
            case .accessoryRectangular: RectangularView(state: state)
            case .accessoryInline: InlineView(state: state)
            case .systemMedium: MediumView(state: state)
            default: SmallView(state: state)
            }
        }
        .containerBackground(for: .widget) {
            ZStack {
                Rectangle().fill(.background)
                LinearGradient(
                    colors: [Color.brand.opacity(0.2), Color.brand.opacity(0.04)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
    }
}

// MARK: - Shared pieces

/// A live bar from the fast's start to its goal.
private struct GoalBar: View {
    let fast: WidgetSnapshot.Fast

    var body: some View {
        ProgressView(timerInterval: fast.start...fast.goalDate, countsDown: false) {
            EmptyView()
        } currentValueLabel: {
            EmptyView()
        }
        .tint(Color.brand)
    }
}

/// The elapsed time since `start`, counting up live, e.g. "13:24:05".
private struct ElapsedText: View {
    let start: Date
    var font: Font = .title

    var body: some View {
        Text(start, style: .timer)
            .font(font)
            .fontDesign(.rounded)
            .bold()
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(0.6)
    }
}

private func goalLine(_ fast: WidgetSnapshot.Fast, isGoalReached: Bool) -> Text {
    isGoalReached
        ? Text("Goal reached")
        : Text("Goal \(fast.goalDate, format: .dateTime.hour().minute())")
}

// MARK: - Small

private struct SmallView: View {
    let state: WidgetState

    var body: some View {
        switch state {
        case .fasting(let name, let fast, let phase, let isGoalReached):
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(name)
                        .font(.headline)
                    Spacer(minLength: 4)
                    Image(systemName: isGoalReached ? "checkmark.seal.fill" : (phase?.systemImage ?? "timer"))
                        .foregroundStyle(Color.brand)
                }
                Spacer(minLength: 0)
                Text("Fasting")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                ElapsedText(start: fast.start)
                GoalBar(fast: fast)
                Text(isGoalReached ? String(localized: "Goal reached") : (phase?.title ?? ""))
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

        case .ready(let name, let summary):
            idle(
                caption: "Active Plan",
                title: name,
                detail: summary,
                footer: "Ready to fast",
                systemImage: "timer"
            )

        case .weeklyNeedsSetup(let name):
            idle(
                caption: "Active Plan",
                title: name,
                detail: String(localized: "Set up your fast days in Intermit."),
                footer: nil,
                systemImage: "calendar"
            )

        case .weekly(let name, let isFastDay, let isCheckedIn, let target, let nextFastDay):
            idle(
                caption: name,
                title: isFastDay ? String(localized: "Fast Day") : String(localized: "Normal Day"),
                detail: isFastDay ? target : nextFastDayText(nextFastDay),
                footer: isFastDay && isCheckedIn ? String(localized: "Checked in") : nil,
                systemImage: isFastDay ? "battery.25percent" : "fork.knife"
            )

        case .noPlan:
            idle(
                caption: "Intermit",
                title: String(localized: "Choose a Plan"),
                detail: String(localized: "Pick a fasting plan to get started."),
                footer: nil,
                systemImage: "list.bullet.clipboard"
            )
        }
    }

    private func idle(caption: LocalizedStringResource, title: String, detail: String, footer: String?, systemImage: String) -> some View {
        idle(caption: String(localized: caption), title: title, detail: detail, footer: footer, systemImage: systemImage)
    }

    private func idle(caption: String, title: String, detail: String, footer: String?, systemImage: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(caption)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Spacer(minLength: 4)
                Image(systemName: systemImage)
                    .foregroundStyle(Color.brand)
            }
            Spacer(minLength: 0)
            Text(title)
                .font(.title2)
                .fontDesign(.rounded)
                .bold()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(detail)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(3)
            if let footer {
                Text(footer)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.brand)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private func nextFastDayText(_ date: Date?) -> String {
    guard let date else { return "" }
    if Calendar.current.isDateInTomorrow(date) {
        return String(localized: "Next fast day: tomorrow")
    }
    return String(localized: "Next fast day: \(date.formatted(.dateTime.weekday(.wide)))")
}

// MARK: - Medium

private struct MediumView: View {
    let state: WidgetState

    var body: some View {
        switch state {
        case .fasting(let name, let fast, let phase, let isGoalReached):
            HStack(spacing: 16) {
                ProgressView(timerInterval: fast.start...fast.goalDate, countsDown: false) {
                    EmptyView()
                } currentValueLabel: {
                    Image(systemName: isGoalReached ? "checkmark" : (phase?.systemImage ?? "timer"))
                        .font(.title2)
                        .foregroundStyle(Color.brand)
                }
                .progressViewStyle(.circular)
                .tint(Color.brand)
                .frame(width: 96, height: 96)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Fasting · \(name)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    ElapsedText(start: fast.start, font: .largeTitle)
                    Label {
                        Text(isGoalReached ? String(localized: "Goal reached") : (phase?.title ?? ""))
                    } icon: {
                        Image(systemName: phase?.systemImage ?? "timer")
                            .foregroundStyle(Color.brand)
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    goalLine(fast, isGoalReached: isGoalReached)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }

        default:
            // Not fasting: the small layout has room to breathe here.
            SmallView(state: state)
        }
    }
}

// MARK: - Lock Screen

private struct CircularView: View {
    let state: WidgetState

    var body: some View {
        switch state {
        case .fasting(_, let fast, let phase, let isGoalReached):
            ProgressView(timerInterval: fast.start...fast.goalDate, countsDown: false) {
                EmptyView()
            } currentValueLabel: {
                Image(systemName: isGoalReached ? "checkmark" : (phase?.systemImage ?? "timer"))
            }
            .progressViewStyle(.circular)

        case .weekly(_, let isFastDay, _, _, _):
            ZStack {
                AccessoryWidgetBackground()
                Image(systemName: isFastDay ? "battery.25percent" : "fork.knife")
                    .font(.title3)
            }

        default:
            ZStack {
                AccessoryWidgetBackground()
                Image(systemName: "timer")
                    .font(.title3)
            }
        }
    }
}

private struct RectangularView: View {
    let state: WidgetState

    var body: some View {
        switch state {
        case .fasting(let name, let fast, let phase, let isGoalReached):
            VStack(alignment: .leading, spacing: 1) {
                Text("\(name) · \(isGoalReached ? String(localized: "Goal reached") : (phase?.title ?? ""))")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                ElapsedText(start: fast.start, font: .title3)
                GoalBar(fast: fast)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

        case .ready(let name, let summary):
            lines(name, summary)

        case .weeklyNeedsSetup(let name):
            lines(name, String(localized: "Set up your fast days"))

        case .weekly(let name, let isFastDay, _, let target, let nextFastDay):
            lines(
                "\(name) · \(isFastDay ? String(localized: "Fast Day") : String(localized: "Normal Day"))",
                isFastDay ? target : nextFastDayText(nextFastDay)
            )

        case .noPlan:
            lines(String(localized: "Intermit"), String(localized: "Choose a fasting plan"))
        }
    }

    private func lines(_ title: String, _ detail: String) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(title)
                .font(.headline)
                .lineLimit(1)
            Text(detail)
                .font(.caption)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct InlineView: View {
    let state: WidgetState

    var body: some View {
        switch state {
        case .fasting(let name, let fast, _, _):
            Text("\(name) · \(Text(fast.start, style: .timer))")
        case .ready(let name, _):
            Text("\(name) · Ready to fast")
        case .weeklyNeedsSetup(let name):
            Text(name)
        case .weekly(let name, let isFastDay, _, _, _):
            Text("\(name) · \(isFastDay ? String(localized: "Fast Day") : String(localized: "Normal Day"))")
        case .noPlan:
            Text("Choose a fasting plan")
        }
    }
}

// MARK: - Widget

struct IntermitWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: WidgetSnapshot.widgetKind, provider: Provider()) { entry in
            IntermitWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Fasting")
        .description("Your plan, how long you've been fasting, and your current phase.")
        .supportedFamilies([
            .systemSmall, .systemMedium,
            .accessoryCircular, .accessoryRectangular, .accessoryInline,
        ])
    }
}

// MARK: - Samples

extension WidgetSnapshot {
    /// A 16:8 fast about 13 hours in, for the widget gallery and previews.
    static var sampleFasting: WidgetSnapshot {
        WidgetSnapshot(
            planName: "16:8",
            planSummary: "Fast 16 h, eat within 8 h, daily",
            fast: Fast(
                start: .now.addingTimeInterval(-13.4 * 3600),
                goalHours: 16,
                phases: [
                    Phase(startHour: 0, title: "Digesting", systemImage: "fork.knife"),
                    Phase(startHour: 4, title: "Blood Sugar Settles", systemImage: "drop.fill"),
                    Phase(startHour: 12, title: "Switching to Fat", systemImage: "flame.fill"),
                    Phase(startHour: 18, title: "Ketones Rise", systemImage: "bolt.fill"),
                ]
            )
        )
    }

    static var sampleReady: WidgetSnapshot {
        WidgetSnapshot(planName: "14:10", planSummary: "Fast 14 h, eat within 10 h, daily")
    }

    static var sampleWeekly: WidgetSnapshot {
        WidgetSnapshot(
            planName: "4:3",
            planSummary: "3 nonconsecutive days a week at about 20% of usual intake",
            isWeeklyPlan: true,
            weekly: Weekly(
                fastDays: [Calendar.current.startOfDay(for: .now)],
                targetText: "About 20% of your usual intake (≈\u{00A0}400 calories)",
                checkedInDays: []
            )
        )
    }
}

#Preview("Small", as: .systemSmall) {
    IntermitWidget()
} timeline: {
    FastEntry(date: .now, snapshot: .sampleFasting)
    FastEntry(date: .now, snapshot: .sampleReady)
    FastEntry(date: .now, snapshot: .sampleWeekly)
    FastEntry(date: .now, snapshot: WidgetSnapshot())
}

#Preview("Medium", as: .systemMedium) {
    IntermitWidget()
} timeline: {
    FastEntry(date: .now, snapshot: .sampleFasting)
}

#Preview("Lock Screen", as: .accessoryRectangular) {
    IntermitWidget()
} timeline: {
    FastEntry(date: .now, snapshot: .sampleFasting)
    FastEntry(date: .now, snapshot: .sampleWeekly)
}

#Preview("Lock Screen Circular", as: .accessoryCircular) {
    IntermitWidget()
} timeline: {
    FastEntry(date: .now, snapshot: .sampleFasting)
}
