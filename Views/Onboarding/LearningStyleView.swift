import SwiftUI

struct LearningStyleView: View {
    @Binding var selectedTags: Set<String>
    let onContinue: () -> Void

    @State private var appeared = false

    private let styles: [(String, String)] = [
        ("reading_struggle", "📚 I sometimes struggle with reading"),
        ("math_confusing", "🔢 Math steps can be confusing"),
        ("distracted", "🎯 I get distracted easily"),
        ("repeat_explanations", "🧠 I need things explained more than once"),
        ("writing_hard", "✍️ Writing is hard for me"),
        ("auditory_learner", "💬 I learn better when someone talks me through it"),
        ("hands_on", "🌟 I learn best by doing, not reading")
    ]

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 12) {
                Text("How does learning\nfeel for you?")
                    .font(SparkTypography.heading1)
                    .foregroundStyle(SparkTheme.charcoal)
                    .multilineTextAlignment(.center)

                Text("There's no wrong answer — this helps Spark support you better.")
                    .font(SparkTypography.bodyLarge)
                    .foregroundStyle(SparkTheme.gray600)
                    .multilineTextAlignment(.center)
            }
            .opacity(appeared ? 1 : 0)

            VStack(spacing: 10) {
                ForEach(styles, id: \.0) { tag, display in
                    stylePill(tag: tag, display: display)
                }
            }
            .padding(.horizontal, 20)
            .opacity(appeared ? 1 : 0)

            Spacer()

            SparkButton(title: "Continue", style: .primary) {
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
        }
    }

    private func stylePill(tag: String, display: String) -> some View {
        let isSelected = selectedTags.contains(tag)
        return Button {
            withAnimation(.spring(response: 0.3)) {
                if isSelected {
                    selectedTags.remove(tag)
                } else {
                    selectedTags.insert(tag)
                }
            }
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        } label: {
            HStack {
                Text(display)
                    .font(SparkTypography.body)
                    .foregroundStyle(isSelected ? .white : SparkTheme.charcoal)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: SparkTheme.radiusMD, style: .continuous)
                    .fill(isSelected ? SparkTheme.teal : .white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: SparkTheme.radiusMD, style: .continuous)
                    .strokeBorder(isSelected ? SparkTheme.teal : SparkTheme.gray200, lineWidth: 1.5)
            )
        }
    }
}
