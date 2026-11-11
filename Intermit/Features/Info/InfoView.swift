import SwiftUI

/// The fasting education hub: short explainers, the common plans, what
/// happens in your body during a fast, and practical tips.
struct InfoView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Start Here") {
                    articleLink(.fasting101)
                    articleLink(.choosingAPlan)
                }

                Section {
                    ForEach(PlanGuide.starterPlans) { plan in
                        NavigationLink {
                            PlanDetailView(plan: plan)
                        } label: {
                            PlanRow(plan: plan)
                        }
                    }
                } header: {
                    Text("Starter Plans")
                } footer: {
                    Text("See every plan, including Advanced ones, in the Plans tab.")
                }

                Section("Your Body") {
                    NavigationLink {
                        FastingTimelineView()
                    } label: {
                        InfoRow(
                            title: "What Happens When You Fast",
                            summary: "How your body changes, hour by hour.",
                            systemImage: "heart.fill"
                        )
                    }
                }

                Section {
                    ForEach(InfoArticle.goodToKnow) { article in
                        articleLink(article)
                    }
                } header: {
                    Text("Good to Know")
                } footer: {
                    Text("Intermit provides general information, not medical advice. Talk to your doctor before starting a fasting plan.")
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Info")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private func articleLink(_ article: InfoArticle) -> some View {
        NavigationLink {
            ArticleView(article: article)
        } label: {
            InfoRow(title: article.title, summary: article.summary, systemImage: article.systemImage)
        }
    }
}

// MARK: - Rows

/// A hub row: tinted icon, title, and a one-line summary.
private struct InfoRow: View {
    let title: LocalizedStringResource
    let summary: LocalizedStringResource
    let systemImage: String

    @ScaledMetric(relativeTo: .body) private var iconSize = 32

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: systemImage)
                .font(.system(size: iconSize * 0.5, weight: .semibold))
                .foregroundStyle(.tint)
                .frame(width: iconSize, height: iconSize)
                .background(Color.accentColor.opacity(0.15), in: RoundedRectangle(cornerRadius: iconSize * 0.3, style: .continuous))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .fontWeight(.semibold)
                Text(summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    InfoView()
}
