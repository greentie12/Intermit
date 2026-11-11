import Foundation
import WidgetKit

/// Keeps the widget's `WidgetSnapshot` in step with the app.
enum WidgetSync {
    /// Builds the snapshot from the current plan and fast, saves it to the App
    /// Group, and asks WidgetKit to refresh, but only when something changed.
    static func update(
        store: FastingStore,
        activePlanID: String,
        customHours: Int,
        now: Date = .now,
        calendar: Calendar = .current
    ) {
        let snapshot = makeSnapshot(
            store: store,
            activePlanID: activePlanID,
            customHours: customHours,
            now: now,
            calendar: calendar
        )
        guard snapshot != WidgetSnapshot.load() else { return }
        snapshot.save()
        WidgetCenter.shared.reloadTimelines(ofKind: WidgetSnapshot.widgetKind)
    }

    static func makeSnapshot(
        store: FastingStore,
        activePlanID: String,
        customHours: Int,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> WidgetSnapshot {
        var snapshot = WidgetSnapshot()
        let plan = PlanGuide.plan(withID: activePlanID)

        if let plan {
            snapshot.planName = plan.name
            snapshot.isWeeklyPlan = plan.weeklyRule != nil
            if case .custom = plan.schedule, let goal = plan.goalHours(customHours: customHours) {
                snapshot.planSummary = String(localized: "Fast \(goal) h, eat within \(24 - goal) h, daily")
            } else {
                snapshot.planSummary = String(localized: plan.scheduleSummary)
            }
        }

        if let fast = store.current {
            // A fast in progress shows the plan it was started with.
            if let planID = fast.planID, let fastPlan = PlanGuide.plan(withID: planID) {
                snapshot.planName = fastPlan.name
            }
            snapshot.fast = WidgetSnapshot.Fast(
                start: fast.start,
                goalHours: fast.goalHours ?? 16,
                phases: FastingStage.all.map {
                    WidgetSnapshot.Phase(
                        startHour: Double($0.startHour),
                        title: String(localized: $0.title),
                        systemImage: $0.systemImage
                    )
                }
            )
        }

        if let plan, plan.weeklyRule != nil,
           let schedule = store.weeklySchedule, schedule.planID == plan.id {
            // Three weeks of fast days, so the widget can roll over at midnight
            // even if the app isn't opened for a while.
            let today = calendar.startOfDay(for: now)
            let fastDays = (0..<21)
                .compactMap { calendar.date(byAdding: .day, value: $0, to: today) }
                .filter { schedule.isFastDay($0, calendar: calendar) }
            snapshot.weekly = WidgetSnapshot.Weekly(
                fastDays: fastDays,
                targetText: plan.fastDayTarget?.description(usualCalories: schedule.usualCalories) ?? "",
                checkedInDays: store.fastDayLogs
                    .filter { $0.planID == plan.id && $0.day >= today }
                    .map(\.day)
            )
        }

        return snapshot
    }
}
