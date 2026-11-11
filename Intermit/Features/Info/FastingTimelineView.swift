import SwiftUI

/// "What Happens When You Fast": the stages of a fast as a vertical timeline.
struct FastingTimelineView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Times are approximate and vary with what you last ate, how active you are, and your metabolism.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)

                VStack(alignment: .leading, spacing: 0) {
                    let stages = FastingStage.all
                    ForEach(stages.indices, id: \.self) { index in
                        StageRow(
                            stage: stages[index],
                            endHour: index + 1 < stages.count ? stages[index + 1].startHour : nil
                        )
                    }
                }
                .padding(16)
                .background(
                    Color(.secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                )
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("What Happens When You Fast")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// One stage: an icon on the timeline line, the hour it starts, and what's happening.
private struct StageRow: View {
    let stage: FastingStage
    /// When the next stage begins; `nil` for the last stage.
    let endHour: Int?

    private var isLast: Bool { endHour == nil }

    @ScaledMetric(relativeTo: .body) private var iconSize = 36

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(spacing: 0) {
                Image(systemName: stage.systemImage)
                    .font(.system(size: iconSize * 0.45, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: iconSize, height: iconSize)
                    .background(Color.accentColor, in: Circle())

                // Line connecting to the next stage.
                if !isLast {
                    Rectangle()
                        .fill(Color.accentColor.opacity(0.3))
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                }
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(hourLabel)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.tint)
                    .textCase(.uppercase)

                Text(stage.title)
                    .font(.headline)

                Text(stage.detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.bottom, isLast ? 0 : 20)
        }
        .accessibilityElement(children: .combine)
    }

    /// e.g. "4–12 hours", or "24+ hours" for the last stage.
    private var hourLabel: LocalizedStringResource {
        if let endHour {
            "\(stage.startHour)–\(endHour) hours"
        } else {
            "\(stage.startHour)+ hours"
        }
    }
}

#Preview {
    NavigationStack {
        FastingTimelineView()
    }
}
