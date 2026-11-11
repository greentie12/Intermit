import SwiftUI

/// A short explainer page, laid out as a series of cards.
struct ArticleView: View {
    let article: InfoArticle

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(article.summary)
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)

                ForEach(article.sections) { section in
                    ArticleSectionCard(section: section)
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(Text(article.title))
        .navigationBarTitleDisplayMode(.large)
    }
}

/// One section of an article: an optional heading, text, and bullet points.
struct ArticleSectionCard: View {
    let section: InfoArticle.Section

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let heading = section.heading {
                Text(heading)
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)
            }

            if let text = section.text {
                Text(text)
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)
            }

            BulletList(items: section.bullets)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            Color(.secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
    }
}

/// Bullet points with a tinted dot, aligned to the first line of each item.
struct BulletList: View {
    let items: [LocalizedStringResource]

    var body: some View {
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(items.indices, id: \.self) { index in
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 6))
                            .foregroundStyle(.tint)
                            .alignmentGuide(.firstTextBaseline) { $0[VerticalAlignment.center] + 4 }
                            .accessibilityHidden(true)

                        Text(items[index])
                            .font(.body)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        ArticleView(article: .fasting101)
    }
}
