import SwiftUI

struct WelcomeView: View {
    let onContinue: () -> Void

    @State private var showTitle = false
    @State private var showSubtitle = false
    @State private var showButton = false
    @State private var sparkProgress: CGFloat = 0

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            VStack(spacing: 16) {
                ZStack {
                    Text("Spark")
                        .font(.system(size: 64, weight: .bold, design: .rounded))
                        .foregroundStyle(SparkTheme.teal)
                        .mask(
                            GeometryReader { geo in
                                Rectangle()
                                    .frame(width: geo.size.width * sparkProgress)
                            }
                        )
                    
                    Text("Spark")
                        .font(.system(size: 64, weight: .bold, design: .rounded))
                        .foregroundStyle(.clear)
                }
                .accessibilityLabel("Spark")

                Text("✦")
                    .font(.system(size: 32))
                    .foregroundStyle(SparkTheme.teal)
                    .opacity(showTitle ? 1 : 0)
                    .scaleEffect(showTitle ? 1 : 0.5)
            }

            Text("Your AI-powered tutor,\nalways by your side.")
                .font(SparkTypography.bodyLarge)
                .foregroundStyle(SparkTheme.gray600)
                .multilineTextAlignment(.center)
                .opacity(showSubtitle ? 1 : 0)
                .offset(y: showSubtitle ? 0 : 10)

            Spacer()

            SparkButton(title: "Let's Begin", style: .primary) {
                onContinue()
            }
            .padding(.horizontal, 48)
            .opacity(showButton ? 1 : 0)
            .offset(y: showButton ? 0 : 20)

            Spacer()
                .frame(height: 40)
        }
        .padding(.horizontal, SparkTheme.spacingXL)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2)) {
                sparkProgress = 1.0
            }
            withAnimation(.spring(response: 0.6).delay(0.8)) {
                showTitle = true
            }
            withAnimation(.easeOut(duration: 0.5).delay(1.5)) {
                showSubtitle = true
            }
            withAnimation(.easeOut(duration: 0.5).delay(2.5)) {
                showButton = true
            }
        }
    }
}
