import SwiftUI

/// The five pages of a plan summary, in scroll order.
enum PlanPage: Int, CaseIterable, Identifiable {
    case overview, body, benefits, warnings, breakingTheFast

    var id: Self { self }

    var title: LocalizedStringResource {
        switch self {
        case .overview: "Overview"
        case .body: "What Happens to Your Body"
        case .benefits: "Key Benefits"
        case .warnings: "Warnings"
        case .breakingTheFast: "How to Break the Fast"
        }
    }

    var systemImage: String {
        switch self {
        case .overview: "info.circle.fill"
        case .body: "figure.stand"
        case .benefits: "checkmark.seal.fill"
        case .warnings: "exclamationmark.triangle.fill"
        case .breakingTheFast: "fork.knife"
        }
    }

    var next: PlanPage? { PlanPage(rawValue: rawValue + 1) }
}

/// A plan summary the user scrolls through page by page, ending with a
/// button to start the plan.
struct PlanDetailView: View {
    let plan: PlanGuide

    @AppStorage(PlanGuide.activePlanStorageKey) private var activePlanID = ""
    @AppStorage(PlanGuide.customHoursStorageKey) private var customHours = 16

    @State private var currentPage: PlanPage = .overview
    /// Visible height of the scroll view, so each page can fill one screen.
    @State private var viewportHeight: CGFloat = 0
    /// Final height of each page, used to work out which page is showing.
    @State private var pageHeights: [PlanPage: CGFloat] = [:]

    @State private var showingAdvancedConfirmation = false
    @State private var showingCustomSetup = false
    @State private var startCount = 0

    private var isActive: Bool { activePlanID == plan.id }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(PlanPage.allCases) { page in
                        pageContainer(page, proxy: proxy)
                    }
                }
            }
            .scrollTargetBehavior(
                PageSnapping(
                    pageHeights: PlanPage.allCases.map { pageHeights[$0] ?? viewportHeight },
                    viewportHeight: viewportHeight
                )
            )
            .scrollIndicators(.hidden)
            // The visible area between the navigation bar and the Start bar;
            // the scroll view's own frame already excludes both.
            .onGeometryChange(for: CGFloat.self) { proxy in
                proxy.size.height
            } action: { height in
                viewportHeight = height
            }
            .onScrollGeometryChange(for: CGFloat.self) { geometry in
                geometry.contentOffset.y + geometry.contentInsets.top
            } action: { _, offset in
                updateCurrentPage(forOffset: offset)
            }
            .overlay(alignment: .trailing) {
                PageIndicator(current: currentPage) { page in
                    withAnimation { proxy.scrollTo(page, anchor: .top) }
                }
                .padding(.trailing, 8)
            }
        }
        .background(background)
        .navigationTitle(plan.name)
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaBar(edge: .bottom) {
            startButton
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
        }
        .confirmationDialog(
            Text("Start \(plan.name)?"),
            isPresented: $showingAdvancedConfirmation,
            titleVisibility: .visible
        ) {
            Button("Start Plan") { start() }
            Button("Not Now", role: .cancel) {}
        } message: {
            Text("This is an Advanced plan. \(Text(plan.readiness))")
        }
        .sheet(isPresented: $showingCustomSetup) {
            CustomPlanSetup(initialHours: customHours) { hours in
                customHours = hours
                start()
            }
        }
        .sensoryFeedback(.success, trigger: startCount)
    }

    // MARK: Pages

    /// One page, at least a screen tall, with a hint to the next page at the bottom.
    private func pageContainer(_ page: PlanPage, proxy: ScrollViewProxy) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            pageContent(page)

            Spacer(minLength: 24)

            if let next = page.next {
                Button {
                    withAnimation { proxy.scrollTo(next, anchor: .top) }
                } label: {
                    Label {
                        Text(next.title)
                    } icon: {
                        Image(systemName: "chevron.down")
                    }
                    .font(.footnote)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("Next: \(Text(next.title))"))
            }
        }
        .padding(.leading, 20)
        .padding(.trailing, 28) // Room for the page indicator.
        .padding(.top, 8)
        .padding(.bottom, 16)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .frame(minHeight: viewportHeight, alignment: .top)
        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { height in
            pageHeights[page] = height
        }
        .id(page)
    }

    @ViewBuilder
    private func pageContent(_ page: PlanPage) -> some View {
        switch page {
        case .overview: OverviewPage(plan: plan, isActive: isActive)
        case .body: BodyPage(plan: plan)
        case .benefits: BenefitsPage(plan: plan)
        case .warnings: WarningsPage(plan: plan)
        case .breakingTheFast: BreakingFastPage(plan: plan)
        }
    }

    /// The current page is the last one whose top has scrolled within the
    /// upper part of the screen.
    private func updateCurrentPage(forOffset offset: CGFloat) {
        var top: CGFloat = 0
        var page = PlanPage.overview
        for candidate in PlanPage.allCases {
            if top <= offset + viewportHeight * 0.4 { page = candidate }
            top += pageHeights[candidate] ?? viewportHeight
        }
        if page != currentPage { currentPage = page }
    }

    private var background: some View {
        ZStack(alignment: .top) {
            Color(.systemGroupedBackground)
            LinearGradient(
                colors: [plan.tier.color.opacity(0.12), .clear],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 360)
        }
        .ignoresSafeArea()
    }

    // MARK: Start

    @ViewBuilder
    private var startButton: some View {
        if isActive {
            Button {
                if case .custom = plan.schedule { showingCustomSetup = true }
            } label: {
                Label(currentPlanTitle, systemImage: "checkmark.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glass)
            .controlSize(.large)
            .accessibilityHint(plan.isCustom ? Text("Change your fasting hours") : Text(""))
        } else {
            Button {
                if plan.isCustom {
                    showingCustomSetup = true
                } else if plan.tier == .advanced {
                    showingAdvancedConfirmation = true
                } else {
                    start()
                }
            } label: {
                Label("Start \(plan.name)", systemImage: "play.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)
            .controlSize(.large)
        }
    }

    private var currentPlanTitle: LocalizedStringResource {
        plan.isCustom ? "Current Plan · \(customHours) h fast" : "Your Current Plan"
    }

    private func start() {
        activePlanID = plan.id
        startCount += 1
    }
}

private extension PlanGuide {
    var isCustom: Bool {
        if case .custom = schedule { true } else { false }
    }
}

// MARK: - Snapping

/// Settles scrolling at the top of a page. Pages taller than the screen can
/// also settle with their bottom edge at the bottom of the screen, and scroll
/// freely in between, so no content is ever out of reach.
private struct PageSnapping: ScrollTargetBehavior {
    /// Heights of the pages, in order, stacked with no spacing.
    let pageHeights: [CGFloat]
    let viewportHeight: CGFloat

    func updateTarget(_ target: inout ScrollTarget, context: TargetContext) {
        guard viewportHeight > 0 else { return }
        let proposed = target.rect.minY
        let maxOffset = max(0, context.contentSize.height - viewportHeight)

        var candidates: [CGFloat] = []
        var top: CGFloat = 0
        for height in pageHeights {
            candidates.append(top)
            if height > viewportHeight + 1 {
                let bottomAligned = top + height - viewportHeight
                // Reading inside a tall page: leave the scroll where it lands.
                if proposed > top, proposed < bottomAligned { return }
                candidates.append(bottomAligned)
            }
            top += height
        }

        let nearest = candidates
            .map { min($0, maxOffset) }
            .min { abs($0 - proposed) < abs($1 - proposed) }
        if let nearest {
            target.rect.origin.y = nearest
        }
    }
}

// MARK: - Page indicator

/// A vertical column of dots on the trailing edge; the current page's dot is
/// stretched. Tapping a dot jumps to that page.
private struct PageIndicator: View {
    let current: PlanPage
    let select: (PlanPage) -> Void

    var body: some View {
        VStack(spacing: 6) {
            ForEach(PlanPage.allCases) { page in
                Button {
                    select(page)
                } label: {
                    Capsule()
                        .fill(page == current ? Color.accentColor : Color.secondary.opacity(0.35))
                        .frame(width: 6, height: page == current ? 22 : 6)
                        // A larger, invisible hit area around each small dot.
                        .frame(width: 22, height: page == current ? 26 : 14)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(page.title))
                .accessibilityAddTraits(page == current ? .isSelected : [])
            }
        }
        .animation(.snappy, value: current)
    }
}

// MARK: - Shared page pieces

/// "1 of 5" with the page's icon, above the page title.
private struct PageHeader: View {
    let page: PlanPage
    var showsTitle = true

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label {
                Text("\(page.rawValue + 1) of \(PlanPage.allCases.count) · \(Text(page.title))")
            } icon: {
                Image(systemName: page.systemImage)
            }
            .font(.footnote)
            .fontWeight(.semibold)
            .foregroundStyle(.tint)
            .accessibilityHidden(!showsTitle) // Overview's title is the plan name instead.

            if showsTitle {
                Text(page.title)
                    .font(.largeTitle)
                    .bold()
                    .accessibilityAddTraits(.isHeader)
            }
        }
    }
}

/// A card with a small uppercase label, used to group page content.
private struct LabeledCard<Content: View>: View {
    let label: LocalizedStringResource
    var systemImage: String? = nil
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .accessibilityHidden(true)
                }
                Text(label)
                    .textCase(.uppercase)
            }
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(.secondary)
            .accessibilityAddTraits(.isHeader)

            content
        }
        .planCard()
    }
}

/// An icon beside a title and sentence.
private struct PointCard: View {
    let point: PlanGuide.Point

    @ScaledMetric(relativeTo: .body) private var iconSize = 36

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: point.systemImage)
                .font(.system(size: iconSize * 0.45, weight: .semibold))
                .foregroundStyle(.tint)
                .frame(width: iconSize, height: iconSize)
                .background(Color.accentColor.opacity(0.15), in: RoundedRectangle(cornerRadius: iconSize * 0.3, style: .continuous))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(point.title)
                    .font(.headline)
                Text(point.text)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .planCard()
        .accessibilityElement(children: .combine)
    }
}

/// A research finding, led by a large number when there is one.
private struct FindingCard: View {
    let finding: PlanGuide.Finding
    var tint: Color = .accentColor

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let highlight = finding.highlight {
                Text(highlight)
                    .font(.system(.largeTitle, design: .rounded))
                    .bold()
                    .foregroundStyle(tint.mix(with: .primary, by: 0.25))
            }

            Text(finding.title)
                .font(.headline)

            Text(finding.text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if let source = finding.source {
                Text("Source: \(source)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.top, 2)
            }
        }
        .planCard()
        .overlay {
            // Colored edge to tell benefits and cautions apart at a glance,
            // following the card's rounded corners.
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(tint)
                .mask(alignment: .leading) {
                    Rectangle().frame(width: 5)
                }
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - 1. Overview

private struct OverviewPage: View {
    let plan: PlanGuide
    let isActive: Bool

    @ScaledMetric(relativeTo: .largeTitle) private var nameSize = 60

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            PageHeader(page: .overview, showsTitle: false)

            VStack(alignment: .leading, spacing: 4) {
                Text(plan.name)
                    .font(.system(size: nameSize, weight: .bold, design: .rounded))
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                    .accessibilityAddTraits(.isHeader)

                if let fullName = plan.fullName {
                    Text(fullName)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 8) {
                PlanBadge(title: plan.tier.title, color: plan.tier.color)
                if isActive {
                    PlanBadge(title: "Current Plan")
                } else if let badge = plan.badge {
                    PlanBadge(title: badge)
                }
            }

            Text(plan.tagline)
                .font(.title3)
                .fixedSize(horizontal: false, vertical: true)

            LabeledCard(label: "Schedule", systemImage: "calendar") {
                PlanScheduleGraphic(schedule: plan.schedule)
                    .padding(.vertical, 2)

                Text(plan.scheduleSummary)
                    .font(.headline)

                Text(plan.example)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(alignment: .top, spacing: 12) {
                LabeledCard(label: "Evidence", systemImage: "books.vertical.fill") {
                    EvidenceMeter(evidence: plan.evidence, note: plan.evidenceNote)
                }
                LabeledCard(label: "Best For", systemImage: "person.fill") {
                    Text(plan.bestFit)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - 2. Body

private struct BodyPage: View {
    let plan: PlanGuide

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            PageHeader(page: .body)

            Text(plan.bodyIntro)
                .font(.title3)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if let hours = plan.dailyFastingHours {
                LabeledCard(label: "During Your Fast", systemImage: "clock.fill") {
                    StageList(fastingHours: hours, isUpperLimit: plan.isCustom)
                }
            }

            ForEach(plan.bodyPoints) { point in
                PointCard(point: point)
            }

            Text("Timing is approximate and varies from person to person.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

/// The body stages reached during a daily fast, ending with where it stops.
private struct StageList: View {
    let fastingHours: Int
    /// For Custom, the hours are a maximum rather than the plan's length.
    var isUpperLimit = false

    @ScaledMetric(relativeTo: .body) private var iconSize = 30

    private var stages: [FastingStage] {
        FastingStage.all.filter { $0.startHour < fastingHours }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(stages.indices, id: \.self) { index in
                let stage = stages[index]
                let end = index + 1 < stages.count ? stages[index + 1].startHour : fastingHours
                row(
                    systemImage: stage.systemImage,
                    caption: "\(stage.startHour)–\(end) h",
                    title: stage.title,
                    filled: true,
                    showsLine: true
                )
            }

            row(
                systemImage: "flag.checkered",
                caption: "\(fastingHours) h",
                title: isUpperLimit ? "Longest Custom Fast" : "Your Fast Ends",
                filled: false,
                showsLine: false
            )
        }
    }

    private func row(
        systemImage: String,
        caption: LocalizedStringResource,
        title: LocalizedStringResource,
        filled: Bool,
        showsLine: Bool
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 0) {
                Image(systemName: systemImage)
                    .font(.system(size: iconSize * 0.45, weight: .semibold))
                    .foregroundStyle(filled ? Color.white : Color.accentColor)
                    .frame(width: iconSize, height: iconSize)
                    .background(filled ? Color.accentColor : Color.accentColor.opacity(0.15), in: Circle())

                if showsLine {
                    Rectangle()
                        .fill(Color.accentColor.opacity(0.3))
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                }
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 1) {
                Text(caption)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.tint)
                    .monospacedDigit()
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            .padding(.bottom, showsLine ? 12 : 0)
            .padding(.top, 2)
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - 3. Benefits

private struct BenefitsPage: View {
    let plan: PlanGuide

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            PageHeader(page: .benefits)

            ForEach(plan.benefits) { finding in
                FindingCard(finding: finding, tint: .accentColor)
            }

            Text("Across studies, fasting mainly works by helping people eat less overall and stick with it.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - 4. Warnings

private struct WarningsPage: View {
    let plan: PlanGuide

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            PageHeader(page: .warnings)

            ForEach(plan.cautions) { finding in
                FindingCard(finding: finding, tint: .orange)
            }

            LabeledCard(label: "When to Try It", systemImage: "figure.walk") {
                Text(plan.readiness)
                    .font(.subheadline)
                    .fixedSize(horizontal: false, vertical: true)
            }

            LabeledCard(label: "Check With Your Doctor First If", systemImage: "stethoscope") {
                BulletList(items: PlanGuide.checkWithDoctor)
                Text(PlanGuide.eatingDisorderNote)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .fixedSize(horizontal: false, vertical: true)
            }

            LabeledCard(label: "Common Side Effects", systemImage: "waveform.path.ecg") {
                Text(PlanGuide.commonSideEffects)
                    .font(.subheadline)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

// MARK: - 5. Breaking the fast

private struct BreakingFastPage: View {
    let plan: PlanGuide

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            PageHeader(page: .breakingTheFast)

            ForEach(plan.breakingTheFast + PlanGuide.generalBreakingTips) { point in
                PointCard(point: point)
            }

            LabeledCard(label: "While Fasting", systemImage: "drop.fill") {
                fastingRule(
                    systemImage: "checkmark.circle.fill",
                    color: .green,
                    title: "OK",
                    text: PlanGuide.allowedWhileFasting
                )
                fastingRule(
                    systemImage: "xmark.circle.fill",
                    color: .red,
                    title: "Breaks a fast",
                    text: PlanGuide.breaksAFast
                )
            }
        }
    }

    private func fastingRule(
        systemImage: String,
        color: Color,
        title: LocalizedStringResource,
        text: LocalizedStringResource
    ) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Image(systemName: systemImage)
                .foregroundStyle(color)
                .accessibilityHidden(true)
            Text("\(Text(title).bold()): \(Text(text))")
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Custom setup

/// Lets the user choose their daily fasting hours before starting Custom.
private struct CustomPlanSetup: View {
    let onStart: (Int) -> Void

    @State private var hours: Int
    @Environment(\.dismiss) private var dismiss

    init(initialHours: Int, onStart: @escaping (Int) -> Void) {
        self.onStart = onStart
        _hours = State(initialValue: min(20, max(12, initialHours)))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Stepper(value: $hours, in: 12...20) {
                        Text("Fast for **\(hours) hours**")
                            .monospacedDigit()
                    }
                    LabeledContent("Eating window", value: "\(24 - hours) hours")
                        .monospacedDigit()
                } footer: {
                    Text("12–14 hours has the strongest research. Past 16 hours, the evidence is limited.")
                }
            }
            .navigationTitle("Custom Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Start") {
                        onStart(hours)
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview("14:10") {
    NavigationStack {
        PlanDetailView(plan: .fourteenTen)
    }
}

#Preview("4:3") {
    NavigationStack {
        PlanDetailView(plan: .fourThree)
    }
}

#Preview("OMAD") {
    NavigationStack {
        PlanDetailView(plan: .omad)
    }
}
