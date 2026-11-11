import Foundation

/// Everything the app says about one fasting plan: how it works, what it does,
/// what the research found, and what to watch out for.
///
/// Content comes from "Intermittent Fasting Research Summary for App Plans"
/// (Nov 2026) and the Fasting App Plan Lineup sheet.
/// Keep claims modest and sourced; have a registered dietitian or physician
/// review this copy before launch.
struct PlanGuide: Identifiable {
    enum Tier {
        case starter, advanced
    }

    enum Schedule {
        /// The same fasting window every day, e.g. 16 hours for 16:8.
        case daily(fastingHours: Int)
        /// Reduced-calorie days on a weekly pattern. `fastDays` are example
        /// days of the week, 0 = Monday.
        case weekly(fastDays: [Int])
        /// The user picks their own daily fasting hours within `range`.
        case custom(range: ClosedRange<Int>)
    }

    /// How strong the research is, from 1 (weak) to 4 (good).
    enum Evidence: Int {
        case weak = 1, mixed, moderate, good
    }

    /// An icon, short title, and sentence, used for body effects and tips.
    struct Point: Identifiable {
        let id = UUID()
        let systemImage: String
        let title: LocalizedStringResource
        let text: LocalizedStringResource
    }

    /// A research finding, optionally led by a headline number like "7.6%".
    struct Finding: Identifiable {
        let id = UUID()
        var highlight: String? = nil
        let title: LocalizedStringResource
        let text: LocalizedStringResource
        var source: String? = nil
    }

    let id: String
    /// Short name, e.g. "16:8" or "OMAD".
    let name: String
    /// Spelled-out name when `name` is an abbreviation, e.g. "One Meal a Day".
    var fullName: LocalizedStringResource? = nil
    /// A short label shown on the plan list, e.g. "Recommended First".
    var badge: LocalizedStringResource? = nil
    let tier: Tier
    let schedule: Schedule
    /// e.g. "Fast 16 h, eat within 8 h, daily".
    let scheduleSummary: LocalizedStringResource
    /// One sentence on why this plan is in the app.
    let tagline: LocalizedStringResource
    /// What a typical day or week looks like.
    let example: LocalizedStringResource
    let evidence: Evidence
    /// e.g. "Moderate, low risk".
    let evidenceNote: LocalizedStringResource
    let bestFit: LocalizedStringResource

    let bodyIntro: LocalizedStringResource
    let bodyPoints: [Point]
    let benefits: [Finding]
    let cautions: [Finding]
    /// When this plan is a good next step, e.g. "After 2–4 comfortable weeks on 12:12."
    let readiness: LocalizedStringResource
    let breakingTheFast: [Point]

    /// Daily fasting hours for plans with a daily window, used to pick which
    /// body stages to show.
    var dailyFastingHours: Int? {
        switch schedule {
        case .daily(let hours): hours
        case .custom(let range): range.upperBound
        case .weekly: nil
        }
    }
}

// MARK: - Storage

extension PlanGuide {
    /// `@AppStorage` key for the ID of the plan the user has started.
    static let activePlanStorageKey = "activePlanID"
    /// `@AppStorage` key for the fasting hours chosen for the Custom plan.
    static let customHoursStorageKey = "customFastingHours"

    static func plan(withID id: String) -> PlanGuide? {
        all.first { $0.id == id }
    }

    static var starterPlans: [PlanGuide] { all.filter { $0.tier == .starter } }
    static var advancedPlans: [PlanGuide] { all.filter { $0.tier == .advanced } }
}

// MARK: - Shared guidance

extension PlanGuide {
    /// Shown on every plan's Warnings page.
    static let checkWithDoctor: [LocalizedStringResource] = [
        "You're under 18 or over 65",
        "You're pregnant or nursing",
        "You have a chronic condition such as diabetes",
        "You take medication for diabetes, since longer fasts can cause low blood sugar",
    ]

    static let eatingDisorderNote: LocalizedStringResource =
        "If you have a history of eating disorders, fasting plans aren't recommended."

    static let commonSideEffects: LocalizedStringResource =
        "Hunger, headaches, fatigue, lightheadedness, dehydration, digestive upset, mood changes, and overeating during eating times. Most people adjust within 2–4 weeks."

    static let allowedWhileFasting: LocalizedStringResource = "Water, black coffee, and plain tea."
    static let breaksAFast: LocalizedStringResource = "Juice, alcohol, creamers, and anything else with calories."

    /// Shared closing tips on every plan's "How to Break the Fast" page.
    static let generalBreakingTips: [Point] = [
        Point(
            systemImage: "fish.fill",
            title: "Lead With Protein",
            text: "Include protein at every meal. Low protein may explain why some fasting trials saw muscle loss."
        ),
        Point(
            systemImage: "dumbbell.fill",
            title: "Keep Strength in the Mix",
            text: "Pair fasting with resistance exercise to help protect lean muscle."
        ),
        Point(
            systemImage: "hand.raised.fill",
            title: "Don't Make Up for Lost Time",
            text: "Eat a normal amount. Overeating during eating times is one of the most common side effects."
        ),
    ]
}

// MARK: - Catalog

extension PlanGuide {
    /// Every plan in the app, in the order they're shown.
    static let all: [PlanGuide] = [
        twelveTwelve, fourteenTen, sixteenEight, fiveTwo,
        eighteenSix, fourThree, alternateDay, omad, custom,
    ]

    static let twelveTwelve = PlanGuide(
        id: "12-12",
        name: "12:12",
        badge: "Recommended First",
        tier: .starter,
        schedule: .daily(fastingHours: 12),
        scheduleSummary: "Fast 12 h, eat within 12 h, daily",
        tagline: "The safe on-ramp, and the recommended first plan for everyone.",
        example: "Eat from 7 AM to 7 PM, then fast overnight.",
        evidence: .moderate,
        evidenceNote: "Moderate, low risk",
        bestFit: "Beginners and anyone starting out",
        bodyIntro: "Twelve hours is the minimum for a fast to count, and most of it passes while you sleep.",
        bodyPoints: [
            Point(
                systemImage: "moon.zzz.fill",
                title: "Mostly Overnight",
                text: "With an early dinner, much of your fast happens during sleep, so the change to your day is small."
            ),
        ],
        benefits: [
            Finding(
                title: "Easy to Stick With",
                text: "Health experts recommend daily fasting like this for beginners because it's gentle and can be lengthened gradually.",
                source: "University of Michigan School of Public Health"
            ),
            Finding(
                title: "May Help Insulin Sensitivity",
                text: "Shorter windows like 12:12 and 14:10 can help your body respond to insulin.",
                source: "Geisinger"
            ),
        ],
        cautions: [
            Finding(
                title: "Small Effects on Its Own",
                text: "12:12 is about building a routine. Don't expect big changes from the schedule alone; what you eat still matters most."
            ),
        ],
        readiness: "A good first plan for anyone who passes the health check below.",
        breakingTheFast: [
            Point(
                systemImage: "sunrise.fill",
                title: "Start With Breakfast",
                text: "Your fast ends in the morning. Eat a balanced breakfast rather than grabbing a snack."
            ),
        ]
    )

    static let fourteenTen = PlanGuide(
        id: "14-10",
        name: "14:10",
        badge: "Best for Metabolic Health",
        tier: .starter,
        schedule: .daily(fastingHours: 14),
        scheduleSummary: "Fast 14 h, eat within 10 h, daily",
        tagline: "The best balance of evidence and ease, and the strongest pick for metabolic health.",
        example: "Eat from 8 AM to 6 PM. Ending by early evening tends to work better.",
        evidence: .moderate,
        evidenceNote: "Moderate, promising",
        bestFit: "Metabolic health and a long-term habit",
        bodyIntro: "Two extra hours past 12:12 give your body more time after digestion before your next meal.",
        bodyPoints: [
            Point(
                systemImage: "clock.arrow.circlepath",
                title: "Earlier Is Better",
                text: "In trials, eating earlier in the day worked better than eating late, so an early window gets more from the same hours."
            ),
        ],
        benefits: [
            Finding(
                highlight: "~70%",
                title: "Kept It Up for a Year",
                text: "Nearly 70% of people in a 10-hour eating pilot stuck with it for at least a year.",
                source: "Wilkinson et al., Cell Metabolism 2020"
            ),
            Finding(
                title: "Heart and Weight Markers Improved",
                text: "People with metabolic syndrome lost weight and waist size, and lowered blood pressure and LDL cholesterol, over 12 weeks. They also slept better.",
                source: "Wilkinson et al., Cell Metabolism 2020"
            ),
            Finding(
                title: "Easy to Adapt To",
                text: "Participants found a 10-hour window easy, while a 6-hour window was hard and caused side effects.",
                source: "Salk Institute"
            ),
        ],
        cautions: [
            Finding(
                title: "Mostly Small Studies",
                text: "The best results come from a small pilot. Larger randomized trials are still needed."
            ),
            Finding(
                title: "Medications May Need Adjusting",
                text: "If you take medication for blood pressure, cholesterol, or blood sugar, a doctor may need to adjust it as your health markers improve.",
                source: "Salk Institute"
            ),
        ],
        readiness: "Try it after 2–4 comfortable weeks on 12:12.",
        breakingTheFast: [
            Point(
                systemImage: "sunrise.fill",
                title: "Break It in the Morning",
                text: "With an 8 AM start, your first meal is breakfast. Make it a real meal with protein."
            ),
            Point(
                systemImage: "moon.fill",
                title: "Finish by Early Evening",
                text: "Aim to finish eating by about 6 PM. Earlier windows did better in trials."
            ),
        ]
    )

    static let sixteenEight = PlanGuide(
        id: "16-8",
        name: "16:8",
        badge: "Most Popular",
        tier: .starter,
        schedule: .daily(fastingHours: 16),
        scheduleSummary: "Fast 16 h, eat within 8 h, daily",
        tagline: "The most popular plan, and simple to follow.",
        example: "Eat from 12 PM to 8 PM, usually by skipping breakfast.",
        evidence: .mixed,
        evidenceNote: "Mixed results in trials",
        bestFit: "Weight-focused people who don't mind skipping breakfast",
        bodyIntro: "Sixteen hours takes you past digestion and into the stage where your body leans more on stored fat.",
        bodyPoints: [
            Point(
                systemImage: "scalemass.fill",
                title: "Fewer Calories, Mostly",
                text: "Experts say the main effect is helping you eat less overall, not a special fat-burning effect."
            ),
        ],
        benefits: [
            Finding(
                title: "Simple to Follow",
                text: "Rated among the best weight-loss methods for simplicity.",
                source: "Baylor Scott & White Health"
            ),
            Finding(
                title: "Works as Well as Dieting",
                text: "Across 99 trials, time-restricted eating led to weight loss similar to traditional calorie-cutting diets.",
                source: "BMJ network meta-analysis, 2025"
            ),
        ],
        cautions: [
            Finding(
                highlight: "65%",
                title: "Watch Your Muscle",
                text: "In one 12-week trial, about 65% of the weight lost was lean mass, versus a typical 20–30%. Skipping breakfast may have lowered protein.",
                source: "TREAT trial, JAMA Internal Medicine 2020"
            ),
            Finding(
                title: "No Better Than Calorie Cutting",
                text: "In a 12-month trial, adding an 8-hour window to calorie cutting didn't improve weight, body fat, or metabolic risk.",
                source: "Liu et al., NEJM 2022"
            ),
            Finding(
                title: "A Signal to Watch",
                text: "A 2024 observational study linked eating within 8 hours to higher heart-related deaths. It couldn't show cause, and the group was small and smoked more, so it isn't proof of harm.",
                source: "Becker's Hospital Review, 2024"
            ),
        ],
        readiness: "Try it after a few comfortable weeks on 14:10.",
        breakingTheFast: [
            Point(
                systemImage: "fork.knife",
                title: "Make Lunch Count",
                text: "Your first meal replaces breakfast, so build it around protein to make up for the missed meal."
            ),
            Point(
                systemImage: "clock.fill",
                title: "Consider an Earlier Window",
                text: "If you can, shift to something like 10 AM to 6 PM. Earlier eating did better in trials."
            ),
        ]
    )

    static let fiveTwo = PlanGuide(
        id: "5-2",
        name: "5:2",
        badge: "Weekly Plan",
        tier: .starter,
        schedule: .weekly(fastDays: [0, 3]),
        scheduleSummary: "2 nonconsecutive days a week at about 500–600 calories",
        tagline: "The most popular weekly plan, for people who don't want to fast every day.",
        example: "Eat normally Tuesday, Wednesday, and Friday through Sunday. Have about 500–600 calories on Monday and Thursday.",
        evidence: .moderate,
        evidenceNote: "Moderate",
        bestFit: "People who'd rather not fast every day",
        bodyIntro: "Instead of a daily window, you cut calories sharply on two days and eat normally on the rest.",
        bodyPoints: [
            Point(
                systemImage: "battery.25percent",
                title: "Low-Calorie Days",
                text: "On fast days your body makes up the energy gap from its stores. Expect more hunger on those days at first."
            ),
            Point(
                systemImage: "calendar",
                title: "Normal Days Between",
                text: "Normal days give your body a break, which is why fast days must never be back to back."
            ),
        ],
        benefits: [
            Finding(
                title: "Matches Daily Dieting",
                text: "Research shows it matches daily calorie restriction for weight loss and blood sugar control.",
                source: "Baylor Scott & White Health"
            ),
            Finding(
                title: "Only Two Hard Days",
                text: "Five days a week are normal eating, which many people find easier than a daily routine.",
                source: "University of Michigan School of Public Health"
            ),
        ],
        cautions: [
            Finding(
                title: "Never Back to Back",
                text: "Fast days must be nonconsecutive. Leave at least one normal day between them."
            ),
            Finding(
                title: "Don't Overcompensate",
                text: "Eat normally on regular days. Overeating can undo the calorie cut from your fast days."
            ),
        ],
        readiness: "A good first plan if daily fasting doesn't suit you.",
        breakingTheFast: [
            Point(
                systemImage: "chart.pie.fill",
                title: "Split Your Fast-Day Calories",
                text: "Many people find one or two small, protein-rich meals easier than several tiny snacks."
            ),
            Point(
                systemImage: "sunrise.fill",
                title: "Ease Back In the Next Day",
                text: "Start the next day with a normal-sized breakfast, not a large one."
            ),
        ]
    )

    static let eighteenSix = PlanGuide(
        id: "18-6",
        name: "18:6",
        tier: .advanced,
        schedule: .daily(fastingHours: 18),
        scheduleSummary: "Fast 18 h, eat within 6 h, daily",
        tagline: "A natural next step after 16:8.",
        example: "Eat from 9 AM to 3 PM. An early window like this did best in trials.",
        evidence: .weak,
        evidenceNote: "Limited",
        bestFit: "Experienced fasters only",
        bodyIntro: "At 18 hours your body has been relying on stored fat for several hours, and ketone levels are climbing.",
        bodyPoints: [
            Point(
                systemImage: "fork.knife",
                title: "Two Meals, Not Three",
                text: "A 6-hour window usually fits two meals. Make sure you still eat enough, especially protein."
            ),
        ],
        benefits: [
            Finding(
                title: "Early Windows Showed Promise",
                text: "Men with prediabetes who ate within 6 hours, ending before 3 PM, had better insulin sensitivity and blood pressure, even without weight loss. They also wanted to eat less in the evening.",
                source: "Sutton et al., Cell Metabolism 2018"
            ),
            Finding(
                title: "Works as Well as Dieting",
                text: "Like other time-restricted plans, it led to weight loss similar to traditional calorie-cutting diets.",
                source: "BMJ network meta-analysis, 2025"
            ),
        ],
        cautions: [
            Finding(
                title: "Thin Evidence",
                text: "Few trials have tested windows this short, and in one study a 6-hour window was hard to follow and caused side effects.",
                source: "Salk Institute"
            ),
            Finding(
                title: "Not for Heart or Blood Sugar Conditions",
                text: "Very short eating windows aren't recommended if you have a heart condition, diabetes, or blood sugar problems."
            ),
            Finding(
                title: "A Signal to Watch",
                text: "A 2024 observational study linked eating within 8 hours to higher heart-related deaths. It couldn't show cause, so it isn't proof of harm.",
                source: "Becker's Hospital Review, 2024"
            ),
        ],
        readiness: "After a few comfortable weeks on 16:8.",
        breakingTheFast: [
            Point(
                systemImage: "sunrise.fill",
                title: "Eat Early",
                text: "Start your window in the morning. Late windows mostly showed no benefit in trials."
            ),
        ]
    )

    static let fourThree = PlanGuide(
        id: "4-3",
        name: "4:3",
        badge: "Best Long-Term Weight Data",
        tier: .advanced,
        schedule: .weekly(fastDays: [0, 2, 4]),
        scheduleSummary: "3 nonconsecutive days a week at about 20% of usual intake",
        tagline: "The best 12-month weight-loss result of any plan in the app.",
        example: "Eat normally Tuesday, Thursday, Saturday, and Sunday. Have about 20% of your usual intake on Monday, Wednesday, and Friday.",
        evidence: .good,
        evidenceNote: "Good, from a 12-month trial",
        bestFit: "Weight loss with structure and support",
        bodyIntro: "Three low-calorie days a week create a steady calorie gap, with normal days in between to recover.",
        bodyPoints: [
            Point(
                systemImage: "battery.25percent",
                title: "Three Low Days",
                text: "On fast days, about 80% fewer calories means your body draws heavily on its stores."
            ),
            Point(
                systemImage: "calendar",
                title: "Recovery Days Between",
                text: "Normal days in between help you stay on track over months, not just weeks."
            ),
        ],
        benefits: [
            Finding(
                highlight: "7.6%",
                title: "More Weight Lost",
                text: "Average weight loss after 12 months was 7.6%, versus 5% with daily calorie counting.",
                source: "Catenacci et al., Annals of Internal Medicine 2025"
            ),
            Finding(
                title: "Healthier Markers",
                text: "Blood pressure, total cholesterol, fasting blood sugar, and A1C all improved more than with calorie counting.",
                source: "University of Colorado Anschutz"
            ),
            Finding(
                highlight: "19%",
                title: "Fewer People Quit",
                text: "19% dropped out, versus nearly 30% with calorie counting.",
                source: "HealthDay"
            ),
        ],
        cautions: [
            Finding(
                title: "Support Matters",
                text: "The trial included an intensive support program. Use check-ins and reminders to get similar structure."
            ),
            Finding(
                title: "Never Back to Back",
                text: "Fast days must be nonconsecutive. Leave at least one normal day between them."
            ),
        ],
        readiness: "Best if you can commit to three fast days a week, with regular check-ins.",
        breakingTheFast: [
            Point(
                systemImage: "chart.pie.fill",
                title: "Plan Your Fast-Day Meals",
                text: "Use your 20% on one or two small meals with protein and vegetables to stay fuller."
            ),
            Point(
                systemImage: "sunrise.fill",
                title: "Ease Back In the Next Day",
                text: "Start the next day with a normal-sized breakfast, not a large one."
            ),
        ]
    )

    static let alternateDay = PlanGuide(
        id: "adf",
        name: "Alternate-Day",
        fullName: "Alternate-Day Fasting",
        tier: .advanced,
        schedule: .weekly(fastDays: [0, 2, 4, 6]),
        scheduleSummary: "Every other day at about 25% of usual intake",
        tagline: "Had a slight weight-loss edge over other plans in the largest recent analysis.",
        example: "Alternate between normal days and fast days at about 25% of your usual intake.",
        evidence: .good,
        evidenceNote: "Good for weight, hard to stick with",
        bestFit: "Highly motivated people",
        bodyIntro: "Every other day is a low-calorie day, so your body switches between drawing on its stores and refueling.",
        bodyPoints: [
            Point(
                systemImage: "arrow.left.arrow.right",
                title: "On and Off",
                text: "Fast days and normal days alternate, so there's never more than a day until your next normal meal."
            ),
        ],
        benefits: [
            Finding(
                highlight: "1.29 kg",
                title: "Beat Daily Dieting",
                text: "The only approach that beat daily calorie restriction across 99 trials, by about 1.29 kg on average.",
                source: "BMJ network meta-analysis, 2025"
            ),
            Finding(
                title: "Better Cholesterol Numbers",
                text: "Lowered total cholesterol, triglycerides, and non-HDL cholesterol compared with time-restricted eating."
            ),
        ],
        cautions: [
            Finding(
                highlight: "38%",
                title: "Many People Quit",
                text: "In a year-long trial, 38% dropped out, versus 29% with calorie counting.",
                source: "Trepanowski et al., JAMA Internal Medicine 2017"
            ),
            Finding(
                title: "LDL Went Up",
                text: "LDL (\"bad\") cholesterol was significantly higher after 12 months.",
                source: "Trepanowski et al., JAMA Internal Medicine 2017"
            ),
            Finding(
                title: "Hard to Hit the Targets",
                text: "People tended to eat more than planned on fast days and less on normal days."
            ),
        ],
        readiness: "Best for experienced fasters, since many people find it hard to keep up.",
        breakingTheFast: [
            Point(
                systemImage: "target",
                title: "Stick to Your Target",
                text: "Plan your fast-day meals ahead so you stay near 25% of your usual intake."
            ),
            Point(
                systemImage: "sunrise.fill",
                title: "Eat Normally Next Day",
                text: "Have regular meals on normal days. Eating too little makes the next fast day harder."
            ),
        ]
    )

    static let omad = PlanGuide(
        id: "omad",
        name: "OMAD",
        fullName: "One Meal a Day",
        badge: "Limited Evidence",
        tier: .advanced,
        schedule: .daily(fastingHours: 23),
        scheduleSummary: "One meal a day, about a 23-hour fast",
        tagline: "Very popular, but with the least research behind it.",
        example: "Eat one full meal, such as an early dinner, then fast until the same time tomorrow.",
        evidence: .weak,
        evidenceNote: "Limited",
        bestFit: "Experienced fasters only",
        bodyIntro: "Close to a full day without calories, every day. Your body spends most of that time running on stored fat and ketones.",
        bodyPoints: [
            Point(
                systemImage: "exclamationmark.bubble.fill",
                title: "Hunger May Not Fade",
                text: "In the main trial, hunger stayed high throughout and didn't ease over time."
            ),
        ],
        benefits: [
            Finding(
                title: "Simple",
                text: "There's only one meal a day to plan."
            ),
            Finding(
                title: "Limited Proof Beyond That",
                text: "No randomized trial of OMAD has run longer than eight weeks, so long-term benefits are unknown.",
                source: "Acibadem"
            ),
        ],
        cautions: [
            Finding(
                title: "Worse Heart Markers",
                text: "Compared with three meals at the same calories, one meal a day raised total and LDL cholesterol and blood pressure.",
                source: "USDA trial, 2007"
            ),
            Finding(
                title: "Higher Morning Blood Sugar",
                text: "It also raised morning blood sugar and slowed the body's insulin response.",
                source: "USDA trial, 2007"
            ),
            Finding(
                title: "Not for Heart or Blood Sugar Conditions",
                text: "Avoid OMAD if you have heart disease, high blood pressure, high cholesterol, diabetes, or blood sugar problems."
            ),
        ],
        readiness: "Only for experienced fasters, given the limited evidence.",
        breakingTheFast: [
            Point(
                systemImage: "fork.knife",
                title: "Make It a Complete Meal",
                text: "One meal has to cover a day's nutrition. Include protein, vegetables, whole grains, and healthy fats."
            ),
            Point(
                systemImage: "tortoise.fill",
                title: "Take Your Time",
                text: "Eat slowly. A large meal after a long fast can cause digestive upset."
            ),
        ]
    )

    static let custom = PlanGuide(
        id: "custom",
        name: "Custom",
        tier: .advanced,
        schedule: .custom(range: 12...20),
        scheduleSummary: "Choose your own daily fast, from 12 to 20 hours",
        tagline: "Set your own window, including 20:4, within safe limits.",
        example: "Pick the fasting hours and eating times that fit your day, such as a 15-hour fast eating from 8 AM to 5 PM.",
        evidence: .mixed,
        evidenceNote: "Depends on the hours you choose",
        bestFit: "Experienced fasters who want flexibility",
        bodyIntro: "What happens depends on how long you fast. Here's what you reach at the longest setting, 20 hours.",
        bodyPoints: [
            Point(
                systemImage: "slider.horizontal.3",
                title: "Your Choice, Your Stages",
                text: "Shorter fasts stay in the early stages; longer ones reach the fat-burning and ketone stages."
            ),
        ],
        benefits: [
            Finding(
                title: "Fits Your Life",
                text: "Choose a window around work, family meals, and workouts, which makes it easier to stick with."
            ),
            Finding(
                title: "Grows With You",
                text: "Fine-tune your fast an hour at a time instead of jumping between fixed plans."
            ),
        ],
        cautions: [
            Finding(
                title: "Evidence Weakens With Length",
                text: "12–14 hours has the most support. Past 16 hours, the research is thin, and 20:4 has almost none of its own."
            ),
            Finding(
                title: "Limited to 20 Hours",
                text: "Custom plans are capped at 20 hours of fasting a day to stay within safe limits."
            ),
        ],
        readiness: "Available once you're ready for Advanced plans.",
        breakingTheFast: [
            Point(
                systemImage: "sunrise.fill",
                title: "Choose an Early Window",
                text: "Windows that end by early evening did better in trials than late ones."
            ),
        ]
    )
}
