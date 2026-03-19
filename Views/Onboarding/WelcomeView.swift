import SwiftUI

struct WelcomeView: View {
    let onContinue: () -> Void

    @State private var showTitle = false
    @State private var showSubtitle = false
    @State private var showButton = false
    @State private var sparkProgress: CGFloat = 0

    // Edit this list to swap emojis for the decorative floating items.
    private let decorativeEmojis = ["💻", "📝", "🖊️", "🎧", "📱", "📚", "🧠", "🧮", "🎒"]

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            GeometryReader { geo in
                let contentWidth = min(geo.size.width * 0.82, 760)

                VStack(spacing: 0) {
                    Spacer(minLength: 56)

                    ZStack {
                        ForEach(Array(decorativeEmojis.enumerated()), id: \.offset) { index, emoji in
                            let point = emojiPosition(for: index, in: contentWidth)
                            Text(emoji)
                                .font(.system(size: emojiFontSize(for: index, width: contentWidth)))
                                .position(x: point.x, y: point.y)
                                .opacity(showTitle ? 1 : 0)
                                .scaleEffect(showTitle ? 1 : 0.7)
                                .animation(.spring(response: 0.6, dampingFraction: 0.78).delay(0.1 * Double(index)), value: showTitle)
                        }

                        VStack(spacing: 10) {
                            Text("Spark")
                                .font(.system(size: min(contentWidth * 0.145, 94), weight: .bold, design: .rounded))
                                .foregroundStyle(SparkTheme.teal)
                                .mask(
                                    GeometryReader { textGeo in
                                        Rectangle()
                                            .frame(width: textGeo.size.width * sparkProgress)
                                    }
                                )

                            Text("Learn with your personal AI tutor")
                                .font(.system(size: min(contentWidth * 0.038, 24), weight: .semibold, design: .default))
                                .foregroundStyle(.black.opacity(0.78))
                                .opacity(showTitle ? 1 : 0)
                                .offset(y: showTitle ? 0 : 8)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Spark")
                    }
                    .frame(width: contentWidth, height: min(geo.size.height * 0.52, 520))


                    Spacer(minLength: 28)

                    VStack(spacing: 18) {
                        SparkCTAButton(title: "Let's Begin", action: onContinue)
                            .frame(width: min(contentWidth * 0.72, 500))
                            .opacity(showButton ? 1 : 0)
                            .offset(y: showButton ? 0 : 16)

                        Text("Your AI-powered tutor, always by your side.")
                            .font(.system(size: 20, weight: .regular, design: .default))
                            .foregroundStyle(.black)
                            .multilineTextAlignment(.center)
                            .opacity(showSubtitle ? 1 : 0)
                            .offset(y: showSubtitle ? 0 : 8)
                    }

                    Spacer(minLength: 44)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2)) {
                sparkProgress = 1.0
            }
            withAnimation(.spring(response: 0.6).delay(0.55)) {
                showTitle = true
            }
            withAnimation(.easeOut(duration: 0.45).delay(1.1)) {
                showButton = true
            }
            withAnimation(.easeOut(duration: 0.45).delay(1.25)) {
                showSubtitle = true
            }
        }
    }

    private func emojiPosition(for index: Int, in width: CGFloat) -> CGPoint {
        let positions: [CGPoint] = [
            CGPoint(x: width * 0.13, y: width * 0.11),
            CGPoint(x: width * 0.50, y: width * 0.07),
            CGPoint(x: width * 0.86, y: width * 0.12),
            CGPoint(x: width * 0.18, y: width * 0.34),
            CGPoint(x: width * 0.84, y: width * 0.34),
            CGPoint(x: width * 0.10, y: width * 0.58),
            CGPoint(x: width * 0.50, y: width * 0.63),
            CGPoint(x: width * 0.86, y: width * 0.56),
            CGPoint(x: width * 0.50, y: width * 0.86)
        ]
        return positions[index]
    }

    private func emojiFontSize(for index: Int, width: CGFloat) -> CGFloat {
        let sizes: [CGFloat] = [
            width * 0.092,
            width * 0.074,
            width * 0.086,
            width * 0.083,
            width * 0.09,
            width * 0.078,
            width * 0.095,
            width * 0.081,
            width * 0.087
        ]
        return min(max(sizes[index], 32), 68)
    }
}

private struct SparkCTAButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 24, weight: .heavy, design: .default))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 64)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(SparkTheme.glassButtonGradient)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.white.opacity(0.22), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .glassIfAvailable(
            isEnabled: true,
            shape: RoundedRectangle(cornerRadius: 14, style: .continuous)
        )
        .shadow(color: SparkTheme.teal.opacity(0.22), radius: 16, y: 8)
    }
}
