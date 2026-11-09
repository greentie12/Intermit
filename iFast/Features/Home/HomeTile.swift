import SwiftUI

/// A tappable card for the Home page's smaller sections, sized to share a row
/// with another tile.
struct HomeTile<Content: View>: View {
    let action: () -> Void
    @ViewBuilder let content: Content

    var body: some View {
        Button(action: action) {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(16)
                .background(
                    Color(.secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 20, style: .continuous)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(.white.opacity(0.25), lineWidth: 0.5)
                }
                .shadow(color: .black.opacity(0.08), radius: 16, y: 8)
                // Make the whole card tappable, not just its text.
                .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

/// Small heading used at the top of each tile: an icon, a title, and a chevron
/// hinting that the tile can be tapped.
struct HomeTileHeader: View {
    let title: LocalizedStringResource
    let systemImage: String

    var body: some View {
        HStack {
            Image(systemName: systemImage)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.tint)

            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)

            Spacer(minLength: 4)

            Image(systemName: "chevron.right")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.tertiary)
        }
    }
}
