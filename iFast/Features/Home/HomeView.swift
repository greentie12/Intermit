import SwiftUI

struct HomeView: View {
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Header band taking up the top eighth of the screen,
                // with the app name pinned to its lower-left corner.
                ZStack(alignment: .bottomLeading) {
                    Color(.systemGray6)
                        .ignoresSafeArea(edges: .top)

                    Text("iFAST")
                        .font(.largeTitle)
                        .bold()
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                }
                .frame(height: geometry.size.height / 8)

                Spacer()
            }
        }
    }
}

#Preview {
    HomeView()
}
