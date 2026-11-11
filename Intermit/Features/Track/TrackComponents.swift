import SwiftUI

// MARK: - Metric kinds

/// The kinds of numbers on the Track tab, each with its own icon so they're
/// easy to tell apart at a glance.
enum MetricKind {
    case fasts, hours, days, average

    var systemImage: String {
        switch self {
        case .fasts: "checkmark.circle.fill"
        case .hours: "clock.fill"
        case .days: "calendar"
        case .average: "chart.bar.fill"
        }
    }

    /// Hours are shown with an "h" after the number; counts have no unit.
    var showsHoursUnit: Bool {
        self == .hours || self == .average
    }
}

/// Spoken form of an hour value, e.g. "42 hours" or "1.5 hours".
private func spokenHours(_ hours: Double, fractionDigits: Int) -> String {
    Measurement(value: hours, unit: UnitDuration.hours)
        .formatted(.measurement(width: .wide, numberFormatStyle: .number.precision(.fractionLength(0...fractionDigits))))
}

// MARK: - Card

extension View {
    /// The raised card background used throughout the Track tab, matching the
    /// Home tiles.
    func trackCard(padding: CGFloat = 16) -> some View {
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
            .shadow(color: .black.opacity(0.08), radius: 16, y: 8)
    }
}

// MARK: - Section

/// A titled group on the Track tab, with an optional date range on the right.
struct TrackSection<Content: View>: View {
    let title: LocalizedStringResource
    var subtitle: String? = nil
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .font(.title3)
                    .bold()
                    .accessibilityAddTraits(.isHeader)

                Spacer(minLength: 8)

                if let subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 4)

            content
        }
    }
}

// MARK: - Icon

/// A metric's icon on a soft tinted square.
struct MetricIcon: View {
    let kind: MetricKind
    @ScaledMetric(relativeTo: .body) private var size = 32

    var body: some View {
        Image(systemName: kind.systemImage)
            .font(.system(size: size * 0.5, weight: .semibold))
            .foregroundStyle(.tint)
            .frame(width: size, height: size)
            .background(Color.accentColor.opacity(0.15), in: RoundedRectangle(cornerRadius: size * 0.3, style: .continuous))
            .accessibilityHidden(true)
    }
}

// MARK: - Value

/// A large number, with a smaller "h" after it for hour values.
struct MetricValue: View {
    let kind: MetricKind
    let value: Double
    var fractionDigits = 0
    var font: Font = .title2

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 2) {
            Text(value, format: .number.precision(.fractionLength(0...fractionDigits)))
                .font(font)
                .fontDesign(.rounded)
                .bold()
                .monospacedDigit()
                .contentTransition(.numericText(value: value))

            if kind.showsHoursUnit {
                Text("h", comment: "Abbreviation for hours, shown after a number")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Lifetime summary card

/// One of the large cards at the top of the Track tab.
struct SummaryCard: View {
    let kind: MetricKind
    let title: LocalizedStringResource
    let value: Double
    var caption: LocalizedStringResource? = nil
    var valueFont: Font = .largeTitle
    /// What VoiceOver reads, e.g. "Total fasting hours".
    let accessibilityTitle: LocalizedStringResource

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                MetricIcon(kind: kind)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
            }

            MetricValue(kind: kind, value: value, font: valueFont)

            if let caption {
                Text(caption)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .trackCard()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(accessibilityTitle))
        .accessibilityValue(kind.showsHoursUnit ? spokenHours(value, fractionDigits: 0) : value.formatted())
    }
}

// MARK: - Period row

/// A row inside a week, month, or year card: icon, label, value, and an
/// optional comparison with the previous period.
struct MetricRow: View {
    let kind: MetricKind
    let title: LocalizedStringResource
    let value: Double
    var fractionDigits = 0
    var caption: LocalizedStringResource? = nil
    var trend: Trend? = nil
    /// The previous period's name for trend text, e.g. "last month".
    var comparedWith: LocalizedStringResource? = nil
    /// What VoiceOver reads, e.g. "Fasting hours this month".
    let accessibilityTitle: LocalizedStringResource

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        // At accessibility text sizes, stack the value under the label so
        // neither gets squeezed.
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
            : AnyLayout(HStackLayout(alignment: .center, spacing: 12))

        layout {
            HStack(spacing: 12) {
                MetricIcon(kind: kind)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                    if let caption {
                        Text(caption)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if !dynamicTypeSize.isAccessibilitySize {
                Spacer(minLength: 8)
            }

            VStack(alignment: dynamicTypeSize.isAccessibilitySize ? .leading : .trailing, spacing: 2) {
                MetricValue(kind: kind, value: value, fractionDigits: fractionDigits)
                if let trend, let comparedWith {
                    TrendLabel(trend: trend, kind: kind, comparedWith: comparedWith)
                }
            }
        }
        .padding(.vertical, 12)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(accessibilityTitle))
        .accessibilityValue(accessibilityValue)
    }

    private var accessibilityValue: String {
        let valueText = kind.showsHoursUnit
            ? spokenHours(value, fractionDigits: fractionDigits)
            : value.formatted()
        guard let trend, let comparedWith else { return valueText }
        return valueText + ", " + TrendLabel.spokenText(trend: trend, kind: kind, comparedWith: comparedWith)
    }
}

// MARK: - Trend

/// A small arrow and change, e.g. "↗ +6 h vs. last month". The arrow and sign
/// carry the meaning, so it doesn't rely on color alone.
struct TrendLabel: View {
    let trend: Trend
    let kind: MetricKind
    let comparedWith: LocalizedStringResource

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: symbol)
                .fontWeight(.bold)
                .foregroundStyle(color)

            switch trend.direction {
            case .flat:
                Text("Same as \(String(localized: comparedWith))")
            case .up, .down:
                Text("\(deltaText) vs. \(String(localized: comparedWith))")
            }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }

    private var deltaText: String {
        let number = trend.delta.formatted(.number.sign(strategy: .always()))
        return kind.showsHoursUnit ? "\(number) h" : number
    }

    private var symbol: String {
        switch trend.direction {
        case .up: "arrow.up.right"
        case .down: "arrow.down.right"
        case .flat: "equal"
        }
    }

    private var color: Color {
        switch trend.direction {
        case .up: .green
        case .down: .orange
        case .flat: .secondary
        }
    }

    /// Text VoiceOver reads for a trend, e.g. "up 6 hours compared with last month".
    static func spokenText(trend: Trend, kind: MetricKind, comparedWith: LocalizedStringResource) -> String {
        let period = String(localized: comparedWith)
        let amount = kind.showsHoursUnit
            ? spokenHours(abs(trend.delta), fractionDigits: 0)
            : abs(trend.delta).formatted()
        switch trend.direction {
        case .up: return String(localized: "up \(amount) compared with \(period)")
        case .down: return String(localized: "down \(amount) compared with \(period)")
        case .flat: return String(localized: "same as \(period)")
        }
    }
}

// MARK: - Ongoing fast

/// Shows the fast in progress, if any, and explains that it isn't counted yet.
struct OngoingFastCard: View {
    let session: FastingSession
    let now: Date
    @ScaledMetric(relativeTo: .title2) private var iconSize = 48

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "timer")
                .font(.system(size: iconSize * 0.5, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: iconSize, height: iconSize)
                .background(Color.accentColor, in: Circle())
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text("Fast in Progress")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)

                Text(elapsed)
                    .font(.title2)
                    .fontDesign(.rounded)
                    .bold()
                    .monospacedDigit()

                Text("Counts toward your totals once it ends.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .trackCard()
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Color.accentColor.opacity(0.5), lineWidth: 1)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Fast in progress")
        .accessibilityValue("\(elapsedSpoken). Counts toward your totals once it ends.")
    }

    private var duration: Duration {
        .seconds(max(0, now.timeIntervalSince(session.start)))
    }

    private var elapsed: String {
        duration.formatted(.units(allowed: [.hours, .minutes], width: .abbreviated))
    }

    private var elapsedSpoken: String {
        duration.formatted(.units(allowed: [.hours, .minutes], width: .wide))
    }
}
