import SwiftUI

/// Top of the Home page: the brand mark and profile button, followed by
/// today's date and a greeting that changes with the time of day.
struct HomeHeader: View {
    var onProfileTap: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                BrandMark()

                Spacer()

                Button(action: onProfileTap) {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 32))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.tint)
                }
                .accessibilityLabel("Profile")
            }

            // Re-render each minute so the greeting stays current.
            TimelineView(.everyMinute) { context in
                VStack(alignment: .leading, spacing: 2) {
                    Text(context.date, format: .dateTime.weekday(.wide).month(.wide).day())
                        .textCase(.uppercase)
                        .font(.footnote)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)

                    Text(Self.greeting(for: context.date))
                        .font(.largeTitle)
                        .bold()
                }
            }
        }
    }

    private static func greeting(for date: Date) -> LocalizedStringResource {
        switch Calendar.current.component(.hour, from: date) {
        case 5..<12: "Good morning"
        case 12..<17: "Good afternoon"
        default: "Good evening"
        }
    }
}

/// The app's logo: an hourglass in a teal rounded square beside the name.
struct BrandMark: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "hourglass")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 30, height: 30)
                .background(Color.accentColor.gradient, in: RoundedRectangle(cornerRadius: 8, style: .continuous))

            Text("Intermit")
                .font(.title3)
                .fontWeight(.semibold)
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    HomeHeader()
        .padding()
}
