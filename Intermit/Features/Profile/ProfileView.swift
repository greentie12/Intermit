import SwiftUI

struct ProfileView: View {
    // Placeholder data for now; pass real values in once they're available.
    var profile: UserProfile = .samplePro
    var stats: FastingStats = .sample

    @AppStorage(AppearanceMode.storageKey) private var appearance: AppearanceMode = .system
    @AppStorage(NotificationService.storageKey) private var notificationsEnabled = false
    @AppStorage(NotificationService.phaseStorageKey) private var phaseNotificationsEnabled = true
    @AppStorage(NotificationService.goalStorageKey) private var goalNotificationsEnabled = true
    @Environment(FastingStore.self) private var fastingStore
    @State private var showingSubscriptionNotice = false
    @State private var showingNotificationsDenied = false

    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.openURL) private var openURL

    /// Turning the toggle on asks iOS for permission; if the user declines,
    /// the toggle switches back off and explains how to allow it in Settings.
    private var notificationsBinding: Binding<Bool> {
        Binding {
            notificationsEnabled
        } set: { isOn in
            notificationsEnabled = isOn
            if isOn {
                Task {
                    if await NotificationService.requestAuthorization() {
                        // Permission can arrive after the toggle flips, so
                        // schedule alerts for a fast already in progress now.
                        await NotificationService.syncFastNotifications(for: fastingStore.current)
                    } else {
                        notificationsEnabled = false
                        showingNotificationsDenied = true
                    }
                }
            } else {
                NotificationService.removeAllPending()
            }
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ProfileHeader(profile: profile)
                }

                Section("Your Stats") {
                    StatsGrid(stats: stats)
                }

                Section("Subscription") {
                    // Stub until StoreKit is connected.
                    Button {
                        showingSubscriptionNotice = true
                    } label: {
                        if profile.isPro {
                            SettingsLabel("Manage Subscription", systemImage: "creditcard.fill")
                        } else {
                            SettingsLabel("Upgrade to Pro", systemImage: "sparkles")
                        }
                    }
                    .sensoryFeedback(.impact(weight: .light), trigger: showingSubscriptionNotice) { _, isShowing in
                        isShowing
                    }
                }

                Section("Settings") {
                    Picker(selection: $appearance) {
                        ForEach(AppearanceMode.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    } label: {
                        SettingsLabel("Appearance", systemImage: "circle.lefthalf.filled")
                    }

                    Toggle(isOn: notificationsBinding) {
                        SettingsLabel("Notifications", systemImage: "bell.fill")
                    }

                    if notificationsEnabled {
                        Toggle(isOn: $phaseNotificationsEnabled) {
                            SettingsDetailLabel(
                                "Phase Updates",
                                detail: "When your fast enters a new metabolic phase",
                                systemImage: "waveform.path.ecg"
                            )
                        }

                        Toggle(isOn: $goalNotificationsEnabled) {
                            SettingsDetailLabel(
                                "Goal Reached",
                                detail: "When you hit your plan's fasting goal",
                                systemImage: "flag.checkered"
                            )
                        }
                    }
                }
                .animation(.default, value: notificationsEnabled)

                Section("Support and Legal") {
                    SettingsLinkRow(
                        title: "Privacy Policy",
                        systemImage: "hand.raised.fill",
                        url: AppLinks.privacyPolicy,
                        placeholderText: "Our privacy policy will be available here soon."
                    )

                    SettingsLinkRow(
                        title: "Terms of Use",
                        systemImage: "doc.text.fill",
                        url: AppLinks.termsOfUse,
                        placeholderText: "Our terms of use will be available here soon."
                    )

                    SettingsLinkRow(
                        title: "Support",
                        systemImage: "questionmark.circle.fill",
                        url: AppLinks.support,
                        placeholderText: "Need help? Support contact details will be available here soon."
                    )
                }

                Section("About") {
                    LabeledContent("Version", value: Bundle.main.versionDisplay)
                        .monospacedDigit()
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .alert("Coming Soon", isPresented: $showingSubscriptionNotice) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Subscriptions aren't available yet.")
            }
            .alert("Notifications Are Off", isPresented: $showingNotificationsDenied) {
                if let url = NotificationService.settingsURL {
                    Button("Open Settings") { openURL(url) }
                }
                Button("Not Now", role: .cancel) {}
            } message: {
                Text("To get reminders, allow notifications for Intermit in Settings.")
            }
            // Keep the toggle honest if notifications were turned off in the
            // Settings app while Intermit was in the background.
            .task(id: scenePhase) {
                guard scenePhase == .active, notificationsEnabled else { return }
                if !(await NotificationService.isAuthorized()) {
                    notificationsEnabled = false
                }
            }
        }
    }
}

// MARK: - Header

/// Avatar with initials, the user's name, and their plan.
private struct ProfileHeader: View {
    let profile: UserProfile

    var body: some View {
        HStack(spacing: 16) {
            Text(profile.initials)
                .font(.title2)
                .bold()
                .foregroundStyle(.tint)
                .frame(width: 64, height: 64)
                .background(Color.accentColor.opacity(0.15), in: Circle())
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(profile.name)
                    .font(.title2)
                    .bold()

                HStack(spacing: 6) {
                    if profile.isPro {
                        Text("PRO")
                            .font(.caption2)
                            .fontWeight(.heavy)
                            .foregroundStyle(.tint)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2)
                            .background(Color.accentColor.opacity(0.15), in: Capsule())
                    }

                    Text(profile.isPro ? "Pro member" : "Free plan")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Stats

/// The user's key fasting numbers in a two-by-two grid.
private struct StatsGrid: View {
    let stats: FastingStats

    var body: some View {
        Grid(horizontalSpacing: 12, verticalSpacing: 20) {
            GridRow {
                StatItem(value: stats.streakDays, unit: nil, label: "Day Streak", systemImage: "flame.fill")
                StatItem(value: stats.totalFasts, unit: nil, label: "Total Fasts", systemImage: "checkmark.circle.fill")
            }
            GridRow {
                StatItem(value: stats.longestHours, unit: "h", label: "Longest", systemImage: "trophy.fill")
                StatItem(value: stats.averageHours, unit: "h", label: "Average", systemImage: "chart.bar.fill")
            }
        }
        .padding(.vertical, 8)
    }
}

private struct StatItem: View {
    let value: Int
    let unit: LocalizedStringResource?
    let label: LocalizedStringResource
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label {
                Text(label)
            } icon: {
                Image(systemName: systemImage)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.tint)
                    .accessibilityHidden(true) // Decorative; the text says it all
            }
            .font(.footnote)
            .foregroundStyle(.secondary)

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value, format: .number)
                    .font(.title)
                    .bold()
                    .monospacedDigit()

                if let unit {
                    Text(unit)
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Settings rows

/// A settings row label with a second line explaining it.
private struct SettingsDetailLabel: View {
    let title: LocalizedStringResource
    let detail: LocalizedStringResource
    let systemImage: String

    init(_ title: LocalizedStringResource, detail: LocalizedStringResource, systemImage: String) {
        self.title = title
        self.detail = detail
        self.systemImage = systemImage
    }

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .foregroundStyle(.primary)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } icon: {
            Image(systemName: systemImage)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.tint)
                .accessibilityHidden(true)
        }
    }
}

/// A settings row label with an accent-colored SF Symbol.
private struct SettingsLabel: View {
    let title: LocalizedStringResource
    let systemImage: String

    init(_ title: LocalizedStringResource, systemImage: String) {
        self.title = title
        self.systemImage = systemImage
    }

    var body: some View {
        Label {
            Text(title)
                .foregroundStyle(.primary)
        } icon: {
            Image(systemName: systemImage)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.tint)
                .accessibilityHidden(true) // Decorative; the text says it all
        }
    }
}

/// Opens `url` in Safari when one is set; otherwise shows a placeholder page.
private struct SettingsLinkRow: View {
    let title: LocalizedStringResource
    let systemImage: String
    let url: URL?
    let placeholderText: LocalizedStringResource

    var body: some View {
        if let url {
            Link(destination: url) {
                SettingsLabel(title, systemImage: systemImage)
            }
        } else {
            NavigationLink {
                InfoPageView(title: title, bodyText: placeholderText)
            } label: {
                SettingsLabel(title, systemImage: systemImage)
            }
        }
    }
}

#Preview("Pro") {
    ProfileView(profile: .samplePro, stats: .sample)
        .environment(FastingStore.preview())
}

#Preview("Free") {
    ProfileView(profile: .sampleFree, stats: .empty)
        .environment(FastingStore.preview())
}
