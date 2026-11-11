import SwiftUI

// Content for the Info tab. Kept as plain data so copy can be edited in one
// place without touching the layout.

// MARK: - Articles

/// A short explainer: a title, a one-line summary, and a few sections.
struct InfoArticle: Identifiable {
    let id: String
    let title: LocalizedStringResource
    let summary: LocalizedStringResource
    let systemImage: String
    let sections: [Section]

    struct Section: Identifiable {
        let id = UUID()
        var heading: LocalizedStringResource? = nil
        var text: LocalizedStringResource? = nil
        var bullets: [LocalizedStringResource] = []
    }
}

extension InfoArticle {
    static let fasting101 = InfoArticle(
        id: "fasting-101",
        title: "Fasting 101",
        summary: "What intermittent fasting is and how it works.",
        systemImage: "book.fill",
        sections: [
            Section(text: "Intermittent fasting is a way of eating that focuses on **when** you eat rather than **what** you eat. You switch between a fasting window, when you have no calories, and an eating window, when you eat your normal meals."),
            Section(
                heading: "How It Works",
                text: "Plans are written as two numbers, like 16:8: 16 hours of fasting followed by an 8-hour eating window. Your fasting window includes the time you're asleep, so most of it passes overnight."
            ),
            Section(
                heading: "Why People Try It",
                bullets: [
                    "It gives your day a simple structure, with fewer decisions about snacking.",
                    "Eating in a shorter window often means eating less overall, which can help with weight management.",
                    "Eating earlier in the day may help your body handle blood sugar, according to early research.",
                ]
            ),
            Section(
                heading: "What It Isn't",
                text: "Fasting isn't a shortcut around a balanced diet. In studies, it worked about as well as regular calorie cutting, not better. What you eat still matters most, and results vary from person to person."
            ),
        ]
    )

    static let choosingAPlan = InfoArticle(
        id: "choosing-a-plan",
        title: "How to Pick a Plan",
        summary: "Find a schedule that fits your life.",
        systemImage: "signpost.right.fill",
        sections: [
            Section(
                heading: "Start Where You Are",
                text: "Begin with 12:12. After 2–4 comfortable weeks, try 14:10, then 16:8 if you want to go further."
            ),
            Section(
                heading: "Fit It Around Your Day",
                bullets: [
                    "Finish eating by early evening if you can, such as 8 AM to 6 PM. Earlier windows did better in trials than late ones.",
                    "Eat dinner with family or friends? A later window is fine. Sticking with it matters more than perfect timing.",
                    "Don't want to fast every day? Try 5:2, with two low-calorie days a week.",
                ]
            ),
            Section(
                heading: "Match Your Goal",
                bullets: [
                    "Metabolic health: 14:10 with an early window.",
                    "Weight loss: 16:8, 5:2, or 4:3.",
                ]
            ),
            Section(
                heading: "Consistency Beats Intensity",
                text: "A plan you can keep most days does more than a strict one you abandon. Most people need 2–4 weeks to adjust, so give a new plan time before changing it."
            ),
        ]
    )

    static let whatBreaksAFast = InfoArticle(
        id: "what-breaks-a-fast",
        title: "What Breaks a Fast",
        summary: "What you can and can't have while fasting.",
        systemImage: "cup.and.saucer.fill",
        sections: [
            Section(
                heading: "Generally Fine",
                bullets: [
                    "Water, still or sparkling",
                    "Black coffee",
                    "Plain tea, including herbal tea",
                ]
            ),
            Section(
                heading: "Breaks a Fast",
                bullets: [
                    "Juice, alcohol, and creamers",
                    "Anything else with calories, including milk and bone broth",
                    "Snacks, however small",
                ]
            ),
            Section(
                heading: "Gray Areas",
                text: "Zero-calorie sweeteners and diet drinks have no calories, but some people find they increase cravings. If they help you stick with your plan, they're a reasonable choice. Always take medications as prescribed, and ask your doctor if a medication needs to be taken with food."
            ),
        ]
    )

    static let handlingHunger = InfoArticle(
        id: "handling-hunger",
        title: "Handling Hunger",
        summary: "Simple ways to make fasting easier.",
        systemImage: "leaf.fill",
        sections: [
            Section(text: "Hunger usually comes in waves rather than building steadily, and for most people it eases within 2–4 weeks as the body adjusts to the new routine."),
            Section(
                heading: "While Fasting",
                bullets: [
                    "Drink water. Thirst is easy to mistake for hunger.",
                    "Stay busy. Hunger is most noticeable when you're bored.",
                    "Black coffee or tea can take the edge off.",
                ]
            ),
            Section(
                heading: "During Your Eating Window",
                bullets: [
                    "Include protein, fiber, and healthy fats to stay full longer.",
                    "Break your fast with a normal-sized, balanced meal rather than a large one.",
                    "Get enough sleep. Being tired makes hunger harder to manage.",
                ]
            ),
        ]
    )

    static let safety = InfoArticle(
        id: "safety",
        title: "Fasting Safely",
        summary: "Who should be careful and when to stop.",
        systemImage: "cross.case.fill",
        sections: [
            Section(text: "Intermittent fasting isn't right for everyone. Talk to your doctor before you start, especially if you have a health condition or take medication."),
            Section(
                heading: "Ask a Doctor First",
                text: "Don't fast without medical advice if you:",
                bullets: [
                    "Are pregnant, breastfeeding, or trying to conceive",
                    "Are under 18 or over 65",
                    "Have, or have had, an eating disorder",
                    "Have diabetes or another chronic condition, or take medication that lowers blood sugar (longer fasts can cause low blood sugar)",
                    "Are underweight",
                ]
            ),
            Section(
                heading: "When to Stop",
                text: "Stop fasting and eat if you feel:",
                bullets: [
                    "Dizzy, faint, or shaky",
                    "Confused or unusually weak",
                    "Unwell in any way that worries you",
                ]
            ),
            Section(text: "Intermit provides general information, not medical advice."),
        ]
    )

    /// Shown in the hub's "Good to Know" section, in order.
    static let goodToKnow: [InfoArticle] = [.whatBreaksAFast, .handlingHunger, .safety]
}

// MARK: - Body timeline

/// A stage of a fast, for the "What Happens When You Fast" timeline.
struct FastingStage: Identifiable {
    let id: Int
    /// When the stage roughly begins, in hours since your last meal.
    let startHour: Int
    let title: LocalizedStringResource
    let detail: LocalizedStringResource
    let systemImage: String
}

extension FastingStage {
    static let all: [FastingStage] = [
        FastingStage(
            id: 0,
            startHour: 0,
            title: "Digesting",
            detail: "Your body digests your last meal and uses its energy. Blood sugar and insulin rise, then gradually fall.",
            systemImage: "fork.knife"
        ),
        FastingStage(
            id: 1,
            startHour: 4,
            title: "Blood Sugar Settles",
            detail: "Digestion winds down and insulin returns to its normal level. Your body starts drawing on stored sugar (glycogen) for energy.",
            systemImage: "drop.fill"
        ),
        FastingStage(
            id: 2,
            startHour: 12,
            title: "Switching to Fat",
            detail: "As glycogen runs low, your body burns more fat for fuel and begins making ketones, an alternative energy source.",
            systemImage: "flame.fill"
        ),
        FastingStage(
            id: 3,
            startHour: 18,
            title: "Ketones Rise",
            detail: "Ketone levels keep climbing. Some people notice steadier energy and less hunger around this point.",
            systemImage: "bolt.fill"
        ),
        FastingStage(
            id: 4,
            startHour: 24,
            title: "Deeper Fasting",
            detail: "Research, mostly in animals, suggests cells step up autophagy, their natural process for recycling worn-out parts. How much this happens in people is still being studied.",
            systemImage: "arrow.triangle.2.circlepath"
        ),
    ]
}
