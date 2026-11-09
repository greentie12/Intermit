import SwiftUI

/// Home tile summarizing the user's fasting totals.
struct StatsCard: View {
    var totalHours = 0
    var totalDays = 0
    var action: () -> Void = {}

    var body: some View {
        HomeTile(action: action) {
            VStack(alignment: .leading, spacing: 14) {
                HomeTileHeader(title: "Your Stats", systemImage: "chart.bar.fill")

                HStack(alignment: .firstTextBaseline, spacing: 16) {
                    stat(value: totalHours, label: "Hours")
                    stat(value: totalDays, label: "Days")
                }
            }
        }
    }

    private func stat(value: Int, label: LocalizedStringResource) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value, format: .number)
                .font(.title2)
                .bold()
                .monospacedDigit()

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    StatsCard(totalHours: 128, totalDays: 9)
        .frame(width: 180, height: 140)
        .padding()
        .background(Color(.systemGroupedBackground))
}
