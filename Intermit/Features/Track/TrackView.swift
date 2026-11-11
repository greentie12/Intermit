import SwiftUI

struct TrackView: View {
    /// The user's fasts, or `nil` while they're loading.
    var sessions: [FastingSession]?

    // Uses the user's calendar, locale, and time zone for day/week/month/year
    // boundaries, and updates if they change.
    @Environment(\.calendar) private var calendar

    var body: some View {
        NavigationStack {
            Group {
                if let sessions {
                    // Refresh every minute so the ongoing fast's timer and
                    // "today" stay current, including across midnight.
                    TimelineView(.everyMinute) { context in
                        let metrics = TrackMetrics(sessions: sessions, now: context.date, calendar: calendar)
                        if metrics.hasData {
                            dashboard(metrics, now: context.date)
                        } else {
                            ContentUnavailableView(
                                "No Fasts Yet",
                                systemImage: "chart.line.uptrend.xyaxis",
                                description: Text("Complete your first fast to see your progress here.")
                            )
                        }
                    }
                } else {
                    // Skeleton while loading: the real layout with zeros, redacted.
                    dashboard(TrackMetrics(sessions: [], calendar: calendar), now: .now)
                        .redacted(reason: .placeholder)
                        .allowsHitTesting(false)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("Loading your stats")
                }
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Track")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private func dashboard(_ metrics: TrackMetrics, now: Date) -> some View {
        ScrollView {
            TrackDashboard(metrics: metrics, now: now)
                .padding(.horizontal)
                .padding(.vertical, 8)
        }
    }
}

// MARK: - Dashboard

/// The full Track layout: lifetime totals first, then this week, month, and year.
private struct TrackDashboard: View {
    let metrics: TrackMetrics
    let now: Date

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            if let ongoing = metrics.ongoing {
                OngoingFastCard(session: ongoing, now: now)
            }

            lifetime
            week
            month
            year
            definitions
        }
    }

    // MARK: Lifetime

    private var lifetime: some View {
        TrackSection(title: "Lifetime") {
            VStack(spacing: 12) {
                SummaryCard(
                    kind: .hours,
                    title: "Total Fasting Hours",
                    value: metrics.lifetime.hours.rounded(),
                    caption: averageCaption,
                    accessibilityTitle: "Total fasting hours"
                )

                // Two half-width cards, stacked at accessibility text sizes.
                let layout = dynamicTypeSize.isAccessibilitySize
                    ? AnyLayout(VStackLayout(spacing: 12))
                    : AnyLayout(HStackLayout(spacing: 12))

                layout {
                    SummaryCard(
                        kind: .fasts,
                        title: "Fasts Completed",
                        value: Double(metrics.lifetime.fasts),
                        valueFont: .title,
                        accessibilityTitle: "Total fasts completed"
                    )
                    SummaryCard(
                        kind: .days,
                        title: "Days Fasted",
                        value: Double(metrics.lifetime.days),
                        valueFont: .title,
                        accessibilityTitle: "Total days fasted"
                    )
                }
                .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var averageCaption: LocalizedStringResource? {
        guard metrics.lifetime.fasts > 0 else { return nil }
        let average = metrics.lifetime.hours / Double(metrics.lifetime.fasts)
        return "Average \(average.formatted(.number.precision(.fractionLength(0...1)))) h per fast"
    }

    // MARK: Periods

    private var week: some View {
        TrackSection(title: "This Week", subtitle: weekRange) {
            VStack(spacing: 0) {
                MetricRow(
                    kind: .hours,
                    title: "Fasting Hours",
                    value: metrics.thisWeek.hours.rounded(),
                    accessibilityTitle: "Fasting hours this week"
                )
                Divider()
                MetricRow(
                    kind: .average,
                    title: "Daily Average",
                    value: metrics.weekDailyAverage,
                    fractionDigits: 1,
                    caption: "Over ^[\(metrics.daysElapsedInWeek) day](inflect: true) so far",
                    accessibilityTitle: "Average fasting hours per day this week"
                )
            }
            .trackCard(padding: 16)
        }
    }

    private var month: some View {
        TrackSection(title: "This Month", subtitle: metrics.month.start.formatted(.dateTime.month(.wide).year())) {
            VStack(spacing: 0) {
                MetricRow(
                    kind: .hours,
                    title: "Fasting Hours",
                    value: metrics.thisMonth.hours.rounded(),
                    trend: Trend(current: metrics.thisMonth.hours, previous: metrics.lastMonthToDate.hours),
                    comparedWith: "last month",
                    accessibilityTitle: "Fasting hours this month"
                )
                Divider()
                MetricRow(
                    kind: .days,
                    title: "Days Fasted",
                    value: Double(metrics.thisMonth.days),
                    caption: "Of ^[\(metrics.daysElapsedInMonth) day](inflect: true) so far",
                    trend: Trend(current: Double(metrics.thisMonth.days), previous: Double(metrics.lastMonthToDate.days)),
                    comparedWith: "last month",
                    accessibilityTitle: "Days fasted this month"
                )
                Divider()
                MetricRow(
                    kind: .average,
                    title: "Daily Average",
                    value: metrics.monthDailyAverage,
                    fractionDigits: 1,
                    accessibilityTitle: "Average fasting hours per day this month"
                )
            }
            .trackCard(padding: 16)
        }
    }

    private var year: some View {
        TrackSection(title: "This Year", subtitle: metrics.year.start.formatted(.dateTime.year())) {
            VStack(spacing: 0) {
                MetricRow(
                    kind: .hours,
                    title: "Fasting Hours",
                    value: metrics.thisYear.hours.rounded(),
                    trend: Trend(current: metrics.thisYear.hours, previous: metrics.lastYearToDate.hours),
                    comparedWith: "last year",
                    accessibilityTitle: "Fasting hours this year"
                )
                Divider()
                MetricRow(
                    kind: .days,
                    title: "Days Fasted",
                    value: Double(metrics.thisYear.days),
                    caption: "Of ^[\(metrics.daysElapsedInYear) day](inflect: true) so far",
                    trend: Trend(current: Double(metrics.thisYear.days), previous: Double(metrics.lastYearToDate.days)),
                    comparedWith: "last year",
                    accessibilityTitle: "Days fasted this year"
                )
                Divider()
                MetricRow(
                    kind: .average,
                    title: "Daily Average",
                    value: metrics.yearDailyAverage,
                    fractionDigits: 1,
                    accessibilityTitle: "Average fasting hours per day this year"
                )
            }
            .trackCard(padding: 16)
        }
    }

    /// e.g. "Nov 9 – 15". The week's end is exclusive, so step back to its last day.
    private var weekRange: String {
        let lastDay = metrics.week.end.addingTimeInterval(-1)
        return (metrics.week.start..<lastDay).formatted(.interval.month(.abbreviated).day())
    }

    // MARK: Definitions

    private var definitions: some View {
        DisclosureGroup {
            VStack(alignment: .leading, spacing: 8) {
                Text("Each fast counts on the day it ends, in your current time zone. All of its hours count toward that day, so an overnight fast is one day fasted.")
                Text("A day fasted is any day on which at least one fast ended.")
                Text("Daily averages divide fasting hours by the days so far in the period, including today.")
                Text("Trends compare with the same point last month or year. For example, Nov 1–9 compares with Oct 1–9.")
                Text("A fast in progress counts once it ends.")
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 8)
        } label: {
            Label("How These Are Calculated", systemImage: "info.circle")
                .font(.subheadline)
                .fontWeight(.semibold)
        }
        .trackCard()
    }
}

#Preview("Sample Data") {
    TrackView(sessions: FastingSession.samples())
}

#Preview("No Fasts") {
    TrackView(sessions: [])
}

#Preview("Loading") {
    TrackView(sessions: nil)
}
