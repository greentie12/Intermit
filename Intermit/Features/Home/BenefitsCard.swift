import SwiftUI

/// Home tile that leads to the Info tab, where users can see how fasting
/// has benefited their body.
struct BenefitsCard: View {
    var action: () -> Void = {}

    var body: some View {
        HomeTile(action: action) {
            VStack(alignment: .leading, spacing: 14) {
                HomeTileHeader(title: "Body Benefits", systemImage: "heart.fill")

                Text("See what fasting is doing for your body.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

#Preview {
    BenefitsCard()
        .frame(width: 180, height: 140)
        .padding()
        .background(Color(.systemGroupedBackground))
}
