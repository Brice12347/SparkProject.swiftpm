import SwiftUI

struct MeetTutorView: View {
    let onContinue: () -> Void

    @State private var currentPage = 0
    @State private var appeared = false
    @State private var autoAdvanceTask: Task<Void, Never>?

    private let features: [(icon: String, title: String, description: String)] = [
        ("camera.fill", "Upload Your Assignment", "Take a photo or upload your homework. Spark reads your handwriting."),
        ("waveform.and.mic", "Live Guidance as You Work", "Your tutor watches as you write and speaks up when you need help."),
        ("pencil.and.outline", "AI Writes on Your Work", "Spark marks corrections and draws examples directly on your assignment."),
        ("doc.text.magnifyingglass", "Session Notes Sidebar", "Every tip is saved so you never have to remember it all yourself."),
        ("lightbulb.max.fill", "Lesson Plans Just for You", "Spark notices what's hard and builds exercises to help you improve."),
        ("chart.line.uptrend.xyaxis", "Your Progress Dashboard", "Watch your strengths grow over time.")
    ]

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 12) {
                Text("Meet your Spark tutor.")
                    .font(SparkTypography.heading1)
                    .foregroundStyle(SparkTheme.charcoal)

                Text("Here's how Spark will help you every time you study.")
                    .font(SparkTypography.bodyLarge)
                    .foregroundStyle(SparkTheme.gray600)
            }
            .multilineTextAlignment(.center)
            .opacity(appeared ? 1 : 0)

            TabView(selection: $currentPage) {
                ForEach(0..<features.count, id: \.self) { index in
                    featureCard(features[index])
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 240)

            HStack(spacing: 8) {
                ForEach(0..<features.count, id: \.self) { index in
                    Circle()
                        .fill(index == currentPage ? SparkTheme.teal : SparkTheme.gray300)
                        .frame(width: 8, height: 8)
                        .animation(.easeInOut(duration: 0.3), value: currentPage)
                }
            }

            Spacer()

            SparkButton(title: "Continue", style: .primary) {
                autoAdvanceTask?.cancel()
                onContinue()
            }
            .padding(.horizontal, 48)

            Spacer()
                .frame(height: 40)
        }
        .padding(.horizontal, SparkTheme.spacingLG)
        .onAppear {
            withAnimation(.spring(response: 0.6).delay(0.2)) {
                appeared = true
            }
            startAutoAdvance()
        }
        .onDisappear {
            autoAdvanceTask?.cancel()
        }
    }

    private func featureCard(_ feature: (icon: String, title: String, description: String)) -> some View {
        VStack(spacing: 20) {
            Image(systemName: feature.icon)
                .font(.system(size: 44))
                .foregroundStyle(SparkTheme.teal)
                .frame(height: 56)

            Text(feature.title)
                .font(SparkTypography.heading2)
                .foregroundStyle(SparkTheme.charcoal)

            Text(feature.description)
                .font(SparkTypography.body)
                .foregroundStyle(SparkTheme.gray600)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: SparkTheme.radiusXL, style: .continuous)
                .fill(.white)
        )
        .padding(.horizontal, 8)
    }

    private func startAutoAdvance() {
        autoAdvanceTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 4_000_000_000)
                guard !Task.isCancelled else { break }
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        currentPage = (currentPage + 1) % features.count
                    }
                }
            }
        }
    }
}
