import SwiftUI

struct TutorPanelView: View {
    @ObservedObject var sessionManager: TutorSessionManager
    let onHelpMe: () -> Void
    let onDone: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            // AI Tutor Header
            VStack(spacing: 12) {
                HStack(spacing: 8) {
                    Text("✦")
                        .font(.system(size: 16))
                        .foregroundStyle(SparkTheme.teal)
                    Text("Spark Tutor")
                        .font(SparkTypography.heading3)
                        .foregroundStyle(SparkTheme.textPrimary(colorScheme))
                }

                WaveformView(isActive: sessionManager.isAISpeaking)
                    .frame(height: 28)
            }
            .padding(.top, 16)
            .padding(.horizontal, 16)

            Divider()
                .padding(.vertical, 12)

            // AI Chat Bubble
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    if sessionManager.currentSpeech.isEmpty && sessionManager.adviceLog.isEmpty {
                        waitingState
                    } else if !sessionManager.currentSpeech.isEmpty {
                        aiBubble(sessionManager.currentSpeech)
                    }

                    ForEach(sessionManager.adviceLog.prefix(3), id: \.id) { advice in
                        pastBubble(advice)
                    }
                }
                .padding(.horizontal, 16)
            }

            Spacer()

            // Action Buttons
            VStack(spacing: 10) {
                SparkButton(title: "Help Me 🙋", style: .secondary) {
                    onHelpMe()
                }

                SparkButton(title: "I'm Done ✓", style: .primary) {
                    onDone()
                }
            }
            .padding(16)
        }
        .background(SparkTheme.surface(colorScheme))
    }

    private var waitingState: some View {
        VStack(spacing: 12) {
            Image(systemName: "pencil.and.outline")
                .font(.system(size: 28))
                .foregroundStyle(SparkTheme.gray400)

            Text("Start writing — I'll watch and help as you go!")
                .font(SparkTypography.body)
                .foregroundStyle(SparkTheme.textSecondary(colorScheme))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    private func aiBubble(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Text("✦")
                    .font(.system(size: 10))
                Text("Spark")
                    .font(SparkTypography.captionBold)
            }
            .foregroundStyle(SparkTheme.teal)

            Text(text)
                .font(SparkTypography.body)
                .foregroundStyle(SparkTheme.textPrimary(colorScheme))
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: SparkTheme.radiusMD, style: .continuous)
                .fill(SparkTheme.teal.opacity(0.08))
        )
    }

    private func pastBubble(_ advice: AdviceEntry) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(advice.topic)
                .font(SparkTypography.captionBold)
                .foregroundStyle(SparkTheme.textPrimary(colorScheme))

            Text(advice.summary)
                .font(SparkTypography.caption)
                .foregroundStyle(SparkTheme.textSecondary(colorScheme))
                .lineLimit(2)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: SparkTheme.radiusSM, style: .continuous)
                .fill(SparkTheme.surfaceSecondary(colorScheme))
        )
    }
}
