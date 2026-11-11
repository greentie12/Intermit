import SwiftUI

// Building blocks shared by the plan list, the plan detail pages, and the
// Info tab.

// MARK: - Card

extension View {
    /// The raised card used on the plan pages, matching the Home tiles.
    func planCard(padding: CGFloat = 16) -> some View {
        self
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                Color(.secondarySystemGroupedBackground),
                in: RoundedRectangle(cornerRadius: 20, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(.white.opacity(0.25), lineWidth: 0.5)
            }
            .shadow(color: .black.opacity(0.06), radius: 12, y: 6)
    }
}

// MARK: - Badges

extension PlanGuide.Tier {
    var title: LocalizedStringResource {
        switch self {
        case .starter: "Starter"
        case .advanced: "Advanced"
        }
    }

    var color: Color {
        switch self {
        case .starter: .green
        case .advanced: .blue
        }
    }
}

/// A small colored capsule, e.g. "Starter" or "Most Popular".
struct PlanBadge: View {
    let title: LocalizedStringResource
    var color: Color = .accentColor

    var body: some View {
        Text(title)
            .font(.caption)
            .fontWeight(.semibold)
            // Blend toward the text color so the label stays readable on its
            // pale background: darker in light mode, lighter in dark mode.
            .foregroundStyle(color.mix(with: .primary, by: 0.4))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.15), in: Capsule())
    }
}

// MARK: - Schedule graphic

/// A picture of the plan's rhythm: a 24-hour bar for daily plans, or a week
/// of days for weekly plans. Decorative; the schedule text says the same.
struct PlanScheduleGraphic: View {
    let schedule: PlanGuide.Schedule
    var compact = false

    var body: some View {
        Group {
            switch schedule {
            case .daily(let hours):
                DayBar(fastingHours: hours, optionalHours: 0, height: compact ? 8 : 12)
            case .custom(let range):
                DayBar(
                    fastingHours: range.lowerBound,
                    optionalHours: range.upperBound - range.lowerBound,
                    height: compact ? 8 : 12
                )
            case .weekly(let fastDays):
                WeekStrip(fastDays: Set(fastDays), compact: compact)
            }
        }
        .accessibilityHidden(true)
    }
}

/// A bar for one day. The solid part is fasting time; the striped part is
/// optional extra fasting (for Custom); the rest is eating time.
private struct DayBar: View {
    let fastingHours: Int
    let optionalHours: Int
    let height: CGFloat

    var body: some View {
        GeometryReader { proxy in
            let hourWidth = proxy.size.width / 24
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.accentColor.opacity(0.2))
                Capsule()
                    .fill(Color.accentColor.opacity(0.5))
                    .frame(width: hourWidth * Double(min(24, fastingHours + optionalHours)))
                Capsule()
                    .fill(Color.accentColor)
                    .frame(width: hourWidth * Double(min(24, fastingHours)))
            }
        }
        .frame(height: height)
    }
}

/// Seven circles, Monday to Sunday, with fast days filled in.
private struct WeekStrip: View {
    let fastDays: Set<Int>
    let compact: Bool

    @ScaledMetric(relativeTo: .caption) private var size = 32
    @Environment(\.calendar) private var calendar

    /// Very short weekday names starting on Monday, e.g. "M", "T", "W".
    private var mondayFirstSymbols: [String] {
        let symbols = calendar.veryShortStandaloneWeekdaySymbols // Sunday first
        return Array(symbols[1...]) + [symbols[0]]
    }

    var body: some View {
        let circle = compact ? size * 0.7 : size
        HStack(spacing: compact ? 4 : 8) {
            ForEach(0..<7, id: \.self) { day in
                let isFastDay = fastDays.contains(day)
                Text(mondayFirstSymbols[day])
                    .font(compact ? .caption2 : .caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(isFastDay ? Color.white : Color.accentColor)
                    .frame(width: circle, height: circle)
                    .background(
                        isFastDay ? Color.accentColor : Color.accentColor.opacity(0.15),
                        in: Circle()
                    )
            }
        }
    }
}

// MARK: - Evidence meter

/// Four segments showing how strong the research is, with a short note.
struct EvidenceMeter: View {
    let evidence: PlanGuide.Evidence
    let note: LocalizedStringResource

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                ForEach(1...4, id: \.self) { level in
                    Capsule()
                        .fill(level <= evidence.rawValue ? Color.accentColor : Color.accentColor.opacity(0.2))
                        .frame(height: 6)
                }
            }
            .frame(maxWidth: 160)
            .accessibilityHidden(true)

            Text(note)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Plan row

/// A plan in a list: name, badges, schedule summary, and a small graphic.
struct PlanRow: View {
    let plan: PlanGuide
    var isActive = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(plan.name)
                        .font(.title3)
                        .fontDesign(.rounded)
                        .bold()
                    if let fullName = plan.fullName {
                        Text(fullName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer(minLength: 8)

                if isActive {
                    PlanBadge(title: "Current Plan")
                } else if let badge = plan.badge {
                    PlanBadge(title: badge, color: plan.tier.color)
                }
            }

            PlanScheduleGraphic(schedule: plan.schedule, compact: true)

            Text(plan.scheduleSummary)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}
