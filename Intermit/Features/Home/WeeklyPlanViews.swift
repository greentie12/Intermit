import SwiftUI

// Views for the weekly low-calorie plans (5:2, 4:3, and alternate-day):
// setup, the Home card, the daily check-in, and the plan's detail screen.

// MARK: - Calendar helpers

extension Calendar {
    /// The seven days of the week containing `date`, starting on the
    /// locale's first weekday.
    func daysOfWeek(containing date: Date) -> [Date] {
        guard let start = dateInterval(of: .weekOfYear, for: date)?.start else { return [] }
        return (0..<7).compactMap { self.date(byAdding: .day, value: $0, to: start) }
    }

    /// Calendar weekday numbers (1 = Sunday) in the locale's order.
    var orderedWeekdays: [Int] {
        (0..<7).map { (firstWeekday - 1 + $0) % 7 + 1 }
    }
}

/// What a weekly plan looks like on a given day, for the Home card and detail.
struct WeeklyPlanStatus {
    let plan: PlanGuide
    let schedule: WeeklySchedule
    let logs: [FastDayLog]
    let now: Date
    let calendar: Calendar

    var isFastDayToday: Bool { schedule.isFastDay(now, calendar: calendar) }

    var todaysLog: FastDayLog? {
        logs.last { calendar.isDate($0.day, inSameDayAs: now) }
    }

    var nextFastDay: Date? { schedule.nextFastDay(after: now, calendar: calendar) }

    var week: [Date] { calendar.daysOfWeek(containing: now) }

    var fastDaysThisWeek: [Date] { week.filter { schedule.isFastDay($0, calendar: calendar) } }

    var completedThisWeek: Int {
        fastDaysThisWeek.filter { day in
            logs.contains { calendar.isDate($0.day, inSameDayAs: day) && $0.outcome == .completed }
        }.count
    }

    var targetText: String {
        plan.fastDayTarget?.description(usualCalories: schedule.usualCalories) ?? ""
    }

    /// e.g. "Wednesday" or "Tomorrow".
    var nextFastDayText: String {
        guard let nextFastDay else { return "" }
        if calendar.isDateInTomorrow(nextFastDay) { return String(localized: "Tomorrow") }
        return nextFastDay.formatted(.dateTime.weekday(.wide))
    }

    /// e.g. "Mon, Wed, Fri" or "Every other day from Nov 11".
    var scheduleText: String {
        if let start = schedule.alternateStart {
            return String(localized: "Every other day from \(start.formatted(.dateTime.month(.abbreviated).day()))")
        }
        let symbols = calendar.shortStandaloneWeekdaySymbols
        return calendar.orderedWeekdays
            .filter(schedule.fastWeekdays.contains)
            .map { symbols[$0 - 1] }
            .formatted(.list(type: .and, width: .short))
    }
}

// MARK: - Week strip

/// The current week, one circle per day. Fast days are filled; completed
/// fast days get a checkmark, skipped ones an X, and today is outlined.
struct WeekProgressStrip: View {
    let status: WeeklyPlanStatus
    var compact = false

    @ScaledMetric(relativeTo: .caption) private var size = 34

    var body: some View {
        let calendar = status.calendar
        let symbols = calendar.veryShortStandaloneWeekdaySymbols
        let side = compact ? size * 0.85 : size

        HStack(spacing: 0) {
            ForEach(status.week, id: \.self) { day in
                let isFast = status.schedule.isFastDay(day, calendar: calendar)
                let log = status.logs.last { calendar.isDate($0.day, inSameDayAs: day) }
                let isToday = calendar.isDate(day, inSameDayAs: status.now)
                let isPast = day < calendar.startOfDay(for: status.now)

                ZStack {
                    Circle()
                        .fill(fill(isFast: isFast, log: log, isPast: isPast))
                    Group {
                        if let log, isFast {
                            Image(systemName: log.outcome == .completed ? "checkmark" : "xmark")
                                .fontWeight(.bold)
                        } else {
                            Text(symbols[calendar.component(.weekday, from: day) - 1])
                                .fontWeight(.semibold)
                        }
                    }
                    .font(compact ? .caption2 : .caption)
                    .foregroundStyle(isFast && log?.outcome != .skipped && !(isPast && log == nil) ? Color.white : Color.accentColor)
                }
                .frame(width: side, height: side)
                .overlay {
                    if isToday {
                        Circle()
                            .strokeBorder(Color.primary.opacity(0.6), lineWidth: 2)
                            .padding(-4)
                    }
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(day, format: .dateTime.weekday(.wide)))
                .accessibilityValue(accessibilityValue(isFast: isFast, log: log, isToday: isToday))
            }
        }
        .padding(.vertical, 4)
    }

    private func fill(isFast: Bool, log: FastDayLog?, isPast: Bool) -> Color {
        guard isFast else { return Color.accentColor.opacity(0.1) }
        if log?.outcome == .skipped || (isPast && log == nil) {
            return Color.accentColor.opacity(0.25)
        }
        return Color.accentColor
    }

    private func accessibilityValue(isFast: Bool, log: FastDayLog?, isToday: Bool) -> String {
        var parts: [String] = []
        if isToday { parts.append(String(localized: "Today")) }
        parts.append(isFast ? String(localized: "Fast day") : String(localized: "Normal day"))
        if isFast, let log {
            parts.append(log.outcome == .completed ? String(localized: "Completed") : String(localized: "Not completed"))
        }
        return parts.joined(separator: ", ")
    }
}

// MARK: - Home card content

/// The Home card's content for a weekly plan: today's status, this week,
/// and a button to check in on a fast day.
struct WeeklyPlanCardContent: View {
    let plan: PlanGuide

    @Environment(FastingStore.self) private var store
    @Environment(\.calendar) private var calendar

    @State private var showingSetup = false
    @State private var showingCheckIn = false
    @State private var showingDetails = false

    /// The saved schedule, if it belongs to this plan.
    private var schedule: WeeklySchedule? {
        store.weeklySchedule.flatMap { $0.planID == plan.id ? $0 : nil }
    }

    var body: some View {
        Group {
            if let schedule {
                // Refreshes each minute so "today" rolls over at midnight.
                TimelineView(.everyMinute) { context in
                    scheduled(WeeklyPlanStatus(
                        plan: plan,
                        schedule: schedule,
                        logs: store.fastDayLogs,
                        now: context.date,
                        calendar: calendar
                    ))
                }
            } else {
                needsSetup
            }
        }
        .sheet(isPresented: $showingSetup) {
            WeeklyScheduleSetup(plan: plan, existing: schedule)
        }
        .sheet(isPresented: $showingCheckIn) {
            FastDayCheckIn(plan: plan, day: .now)
        }
        .sheet(isPresented: $showingDetails) {
            WeeklyPlanView(plan: plan)
        }
    }

    private var needsSetup: some View {
        VStack(alignment: .leading, spacing: 12) {
            header(
                caption: "Active Plan",
                title: Text(plan.name),
                subtitle: Text(plan.scheduleSummary),
                systemImage: "calendar"
            )

            Button {
                showingSetup = true
            } label: {
                Label("Set Up Fast Days", systemImage: "calendar.badge.plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)
            .tint(.accentColor)
        }
    }

    private func scheduled(_ status: WeeklyPlanStatus) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            if status.isFastDayToday {
                header(
                    caption: "\(plan.name) · Fast Day",
                    title: Text("Today's a Fast Day"),
                    subtitle: Text(status.targetText),
                    systemImage: "battery.25percent"
                )
            } else {
                header(
                    caption: "\(plan.name) · Normal Day",
                    title: Text("Eat Normally Today"),
                    subtitle: Text("Next fast day: \(status.nextFastDayText)"),
                    systemImage: "fork.knife"
                )
            }

            WeekProgressStrip(status: status, compact: true)

            Text("\(status.completedThisWeek) of \(status.fastDaysThisWeek.count) fast days done this week")
                .font(.footnote)
                .foregroundStyle(.secondary)

            if status.isFastDayToday {
                if let log = status.todaysLog {
                    Label(
                        log.outcome == .completed ? "Fast day complete" : "Checked in for today",
                        systemImage: log.outcome == .completed ? "checkmark.circle.fill" : "checkmark.circle"
                    )
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.tint)
                } else {
                    Button {
                        showingCheckIn = true
                    } label: {
                        Label("Complete Fast Day", systemImage: "checkmark")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.glassProminent)
                    .tint(.accentColor)
                }
            }

            Button {
                showingDetails = true
            } label: {
                HStack {
                    Text("Plan Details")
                        .fontWeight(.semibold)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.tertiary)
                }
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.accentColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    private func header(caption: LocalizedStringResource, title: Text, subtitle: Text, systemImage: String) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(caption)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                title
                    .font(.title)
                    .bold()
                subtitle
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            Image(systemName: systemImage)
                .symbolRenderingMode(.hierarchical)
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(Color.accentColor.opacity(0.9))
                .padding(10)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .accessibilityHidden(true)
        }
    }
}

// MARK: - Setup

/// Lets the user choose their fast days and calorie target for a weekly plan.
struct WeeklyScheduleSetup: View {
    let plan: PlanGuide
    /// Called after saving, e.g. to make this the active plan.
    var onSave: () -> Void = {}

    @Environment(FastingStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.calendar) private var calendar

    @State private var weekdays: Set<Int>
    @State private var alternateStartsToday = true
    @State private var showsCalories: Bool
    @State private var usualCalories: Int

    init(plan: PlanGuide, existing: WeeklySchedule?, onSave: @escaping () -> Void = {}) {
        self.plan = plan
        self.onSave = onSave

        // Start from the user's saved days, or the plan's example days.
        var defaultDays: Set<Int> = []
        if case .weekly(let indexes) = plan.schedule {
            defaultDays = WeeklySchedule.calendarWeekdays(fromMondayIndexes: indexes)
        }
        _weekdays = State(initialValue: existing?.fastWeekdays.isEmpty == false ? existing!.fastWeekdays : defaultDays)
        _showsCalories = State(initialValue: existing?.usualCalories != nil)
        _usualCalories = State(initialValue: existing?.usualCalories ?? 2000)
    }

    private var requiredCount: Int? {
        if case .weekdays(let count) = plan.weeklyRule { count } else { nil }
    }

    private var isValid: Bool {
        guard let requiredCount else { return true }
        return WeeklySchedule.isValid(weekdays: weekdays, count: requiredCount)
    }

    var body: some View {
        NavigationStack {
            Form {
                if let requiredCount {
                    Section {
                        WeekdayPicker(selection: $weekdays)
                    } header: {
                        Text("Choose \(requiredCount) Fast Days")
                    } footer: {
                        Text(validationMessage(requiredCount))
                    }
                } else {
                    Section {
                        Picker("First fast day", selection: $alternateStartsToday) {
                            Text("Today").tag(true)
                            Text("Tomorrow").tag(false)
                        }
                        .pickerStyle(.segmented)
                    } header: {
                        Text("First Fast Day")
                    } footer: {
                        Text("After that, every other day is a fast day.")
                    }
                }

                if let target = plan.fastDayTarget {
                    Section {
                        if target.usesUsualIntake {
                            Toggle("Show a calorie number", isOn: $showsCalories)
                            if showsCalories {
                                Stepper(value: $usualCalories, in: 1200...4000, step: 100) {
                                    LabeledContent("Usual daily calories") {
                                        Text(usualCalories, format: .number)
                                            .monospacedDigit()
                                    }
                                }
                            }
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text("On fast days")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text(target.description(usualCalories: showsCalories ? usualCalories : nil))
                                .fontWeight(.semibold)
                        }
                        .accessibilityElement(children: .combine)
                    } header: {
                        Text("Fast-Day Target")
                    } footer: {
                        Text("Eat normally on other days. Stop and eat if you feel dizzy, faint, or unwell.")
                    }
                }
            }
            .navigationTitle("\(plan.name) Fast Days")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(!isValid)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func validationMessage(_ count: Int) -> LocalizedStringResource {
        if weekdays.count != count {
            return "Choose \(count) days. \(weekdays.count) selected."
        }
        if !isValid {
            return "Leave at least one normal day between fast days, including over the weekend."
        }
        return "Fast days are never back to back."
    }

    private func save() {
        var schedule = WeeklySchedule(planID: plan.id, startDate: calendar.startOfDay(for: .now))
        if requiredCount != nil {
            schedule.fastWeekdays = weekdays
        } else {
            let today = calendar.startOfDay(for: .now)
            schedule.alternateStart = alternateStartsToday
                ? today
                : calendar.date(byAdding: .day, value: 1, to: today)
        }
        if plan.fastDayTarget?.usesUsualIntake == true, showsCalories {
            schedule.usualCalories = usualCalories
        }
        store.setWeeklySchedule(schedule)
        onSave()
        dismiss()
    }
}

/// Seven toggleable day circles in the locale's week order.
private struct WeekdayPicker: View {
    @Binding var selection: Set<Int>

    @Environment(\.calendar) private var calendar
    @ScaledMetric(relativeTo: .body) private var size = 38

    var body: some View {
        HStack(spacing: 0) {
            ForEach(calendar.orderedWeekdays, id: \.self) { weekday in
                let isSelected = selection.contains(weekday)
                Button {
                    if isSelected {
                        selection.remove(weekday)
                    } else {
                        selection.insert(weekday)
                    }
                } label: {
                    Text(calendar.veryShortStandaloneWeekdaySymbols[weekday - 1])
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(isSelected ? Color.white : Color.accentColor)
                        .frame(width: size, height: size)
                        .background(isSelected ? Color.accentColor : Color.accentColor.opacity(0.12), in: Circle())
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
                .accessibilityLabel(calendar.standaloneWeekdaySymbols[weekday - 1])
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .padding(.vertical, 4)
        .sensoryFeedback(.selection, trigger: selection)
    }
}

// MARK: - Check-in

/// Asks how a fast day went and how the user feels, then saves it.
struct FastDayCheckIn: View {
    let plan: PlanGuide
    let day: Date

    @Environment(FastingStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var outcome: FastDayLog.Outcome = .completed
    @State private var feeling: FastDayLog.Feeling = .good

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Stayed near your target", selection: $outcome) {
                        Text("Yes").tag(FastDayLog.Outcome.completed)
                        Text("Not Quite").tag(FastDayLog.Outcome.skipped)
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Did You Stay Near Your Target?")
                } footer: {
                    if outcome == .skipped {
                        Text("That's okay. Eat normally tomorrow and pick up on your next fast day.")
                    } else if let target = plan.fastDayTarget {
                        Text(target.description(usualCalories: store.weeklySchedule?.usualCalories))
                    }
                }

                Section {
                    Picker("How you feel", selection: $feeling) {
                        ForEach(FastDayLog.Feeling.allCases, id: \.self) { feeling in
                            Text(feeling.title).tag(feeling)
                        }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("How Do You Feel?")
                } footer: {
                    switch feeling {
                    case .good:
                        EmptyView()
                    case .hard:
                        Text("Fast days often get easier after 2–4 weeks. Drinking water and eating some protein can help.")
                    case .unwell:
                        Text("Stop and eat if you feel dizzy, faint, or unwell. If it keeps happening, try a gentler plan like \(gentlerPlan) and talk to your doctor.")
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Fast Day Check-In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        store.logFastDay(on: day, planID: plan.id, outcome: outcome, feeling: feeling)
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
        .sensoryFeedback(.success, trigger: store.fastDayLogs.count)
    }

    /// A less demanding plan to suggest if fast days make the user unwell.
    private var gentlerPlan: String {
        plan.id == PlanGuide.fiveTwo.id ? PlanGuide.fourteenTen.name : PlanGuide.fiveTwo.name
    }
}

// MARK: - Detail

/// Opened from the Home card: today, this week, the schedule, tips, and
/// recent check-ins.
struct WeeklyPlanView: View {
    let plan: PlanGuide

    @Environment(FastingStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.calendar) private var calendar

    @State private var showingSetup = false
    @State private var showingCheckIn = false

    var body: some View {
        NavigationStack {
            Group {
                if let schedule = store.weeklySchedule, schedule.planID == plan.id {
                    TimelineView(.everyMinute) { context in
                        content(WeeklyPlanStatus(
                            plan: plan,
                            schedule: schedule,
                            logs: store.fastDayLogs,
                            now: context.date,
                            calendar: calendar
                        ))
                    }
                } else {
                    ContentUnavailableView("No Fast Days Set", systemImage: "calendar")
                }
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle(plan.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showingSetup) {
                WeeklyScheduleSetup(plan: plan, existing: store.weeklySchedule)
            }
            .sheet(isPresented: $showingCheckIn) {
                FastDayCheckIn(plan: plan, day: .now)
            }
        }
    }

    private func content(_ status: WeeklyPlanStatus) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                today(status)
                thisWeek(status)
                scheduleCard(status)
                tips
                recentCheckIns

                Text("Intermit provides general information, not medical advice. Stop and eat if you feel dizzy, faint, or unwell.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)
            }
            .padding()
        }
    }

    private func today(_ status: WeeklyPlanStatus) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Today", systemImage: status.isFastDayToday ? "battery.25percent" : "fork.knife")

            Text(status.isFastDayToday ? "Today's a Fast Day" : "Eat Normally Today")
                .font(.title2)
                .bold()

            Text(status.isFastDayToday
                 ? status.targetText
                 : String(localized: "Next fast day: \(status.nextFastDayText)"))
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if status.isFastDayToday {
                if status.todaysLog == nil {
                    Button {
                        showingCheckIn = true
                    } label: {
                        Label("Complete Fast Day", systemImage: "checkmark")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.glassProminent)
                    .tint(.accentColor)
                } else {
                    Button {
                        showingCheckIn = true
                    } label: {
                        Label("Update Check-In", systemImage: "pencil")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.glass)
                }
            }
        }
        .planCard()
    }

    private func thisWeek(_ status: WeeklyPlanStatus) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("This Week", systemImage: "calendar")
            WeekProgressStrip(status: status)
            Text("\(status.completedThisWeek) of \(status.fastDaysThisWeek.count) fast days done")
                .font(.subheadline)
                .fontWeight(.semibold)
        }
        .planCard()
    }

    private func scheduleCard(_ status: WeeklyPlanStatus) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Your Fast Days", systemImage: "calendar.badge.clock")
            Text(status.scheduleText)
                .font(.headline)
            Text(status.targetText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Button("Change Fast Days") { showingSetup = true }
                .font(.subheadline)
                .fontWeight(.semibold)
        }
        .planCard()
    }

    private var tips: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("Fast-Day Tips", systemImage: "lightbulb.fill")
            ForEach(plan.breakingTheFast + [PlanGuide.generalBreakingTips[0]]) { tip in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: tip.systemImage)
                        .foregroundStyle(.tint)
                        .frame(width: 24)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(tip.title)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text(tip.text)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .accessibilityElement(children: .combine)
            }
        }
        .planCard()
    }

    @ViewBuilder
    private var recentCheckIns: some View {
        let recent = store.fastDayLogs.filter { $0.planID == plan.id }.suffix(5).reversed()
        if !recent.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                sectionLabel("Recent Check-Ins", systemImage: "list.bullet")
                ForEach(Array(recent)) { log in
                    HStack {
                        Image(systemName: log.outcome == .completed ? "checkmark.circle.fill" : "xmark.circle")
                            .foregroundStyle(log.outcome == .completed ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))
                            .accessibilityHidden(true)
                        Text(log.day, format: .dateTime.weekday(.wide).month(.abbreviated).day())
                            .font(.subheadline)
                        Spacer()
                        if let feeling = log.feeling {
                            Text(feeling.title)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityValue(log.outcome == .completed ? Text("Completed") : Text("Not completed"))
                }
            }
            .planCard()
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
}

// MARK: - Previews

#Preview("Card · Fast Day") {
    let calendar = Calendar.current
    let today = calendar.component(.weekday, from: .now)
    return WeeklyPlanCardContent(plan: .fourThree)
        .padding()
        .environment(FastingStore.preview(
            weeklySchedule: WeeklySchedule(
                planID: "4-3",
                fastWeekdays: [today, (today + 1) % 7 + 1, (today + 3) % 7 + 1],
                usualCalories: 2000
            )
        ))
}

#Preview("Detail") {
    WeeklyPlanView(plan: .alternateDay)
        .environment(FastingStore.preview(
            weeklySchedule: WeeklySchedule(
                planID: "adf",
                alternateStart: Calendar.current.date(byAdding: .day, value: -4, to: Calendar.current.startOfDay(for: .now)),
                usualCalories: 2200
            ),
            fastDayLogs: [
                FastDayLog(day: Calendar.current.date(byAdding: .day, value: -4, to: Calendar.current.startOfDay(for: .now))!, planID: "adf", outcome: .completed, feeling: .hard),
                FastDayLog(day: Calendar.current.date(byAdding: .day, value: -2, to: Calendar.current.startOfDay(for: .now))!, planID: "adf", outcome: .completed, feeling: .good),
            ]
        ))
}

#Preview("Setup · 4:3") {
    WeeklyScheduleSetup(plan: .fourThree, existing: nil)
        .environment(FastingStore.preview())
}
