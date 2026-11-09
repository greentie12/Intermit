import SwiftUI

/// A simple page with a title and body text, used for Privacy Policy,
/// Terms of Use, and Support until the real pages are available.
struct InfoPageView: View {
    let title: LocalizedStringResource
    let bodyText: LocalizedStringResource

    var body: some View {
        ScrollView {
            Text(bodyText)
                .font(.body)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
                .background(
                    Color(.secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                )
                .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(Text(title))
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        InfoPageView(
            title: "Privacy Policy",
            bodyText: "Our privacy policy will be available here soon."
        )
    }
}
