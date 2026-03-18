import SwiftUI

struct TutorPanelView: View {
    @ObservedObject var sessionManager: TutorSessionManager
    let onHelpMe: () -> Void
    let onStudentMessage: (String) -> Void
    let onDone: () -> Void

    @StateObject private var speechRecognition = SpeechRecognitionService.shared
    @State private var showMicPermissionAlert = false
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
                    if sessionManager.isAnalyzing {
                        analyzingState
                    } else if sessionManager.currentSpeech.isEmpty && sessionManager.adviceLog.isEmpty {
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
                HStack(spacing: 10) {
                    SparkButton(title: "Help Me 🙋", style: .secondary) {
                        onHelpMe()
                    }
                    .disabled(sessionManager.isAnalyzing || speechRecognition.isRecording)
                    .opacity(sessionManager.isAnalyzing ? 0.5 : 1)

                    Button {
                        toggleRecording()
                    } label: {
                        Image(systemName: speechRecognition.isRecording ? "mic.fill" : "mic")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(speechRecognition.isRecording ? .white : SparkTheme.teal)
                            .frame(width: 48, height: 48)
                            .background(
                                RoundedRectangle(cornerRadius: SparkTheme.radiusMD, style: .continuous)
                                    .fill(speechRecognition.isRecording ? Color.red : SparkTheme.teal.opacity(0.12))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: SparkTheme.radiusMD, style: .continuous)
                                    .strokeBorder(speechRecognition.isRecording ? Color.red : SparkTheme.teal.opacity(0.3), lineWidth: 1)
                            )
                    }
                    .disabled(sessionManager.isAnalyzing)
                    .accessibilityLabel(speechRecognition.isRecording ? "Stop recording" : "Talk to tutor")
                }

                if speechRecognition.isRecording && !speechRecognition.transcript.isEmpty {
                    Text(speechRecognition.transcript)
                        .font(SparkTypography.caption)
                        .foregroundStyle(SparkTheme.textSecondary(colorScheme))
                        .padding(.horizontal, 8)
                        .lineLimit(2)
                }

                SparkButton(title: "I'm Done ✓", style: .primary) {
                    onDone()
                }
            }
            .padding(16)
        }
        .background(SparkTheme.surface(colorScheme))
        .alert("Microphone Access", isPresented: $showMicPermissionAlert) {
            Button("OK") {}
        } message: {
            Text("Please enable Speech Recognition and Microphone access in Settings to talk to your tutor.")
        }
    }

    private var analyzingState: some View {
        HStack(spacing: 10) {
            ProgressView()
                .tint(SparkTheme.teal)
            Text("Analyzing your work…")
                .font(SparkTypography.body)
                .foregroundStyle(SparkTheme.textSecondary(colorScheme))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    private var waitingState: some View {
        VStack(spacing: 12) {
            Image(systemName: "pencil.and.outline")
                .font(.system(size: 28))
                .foregroundStyle(SparkTheme.gray400)

            Text("Write your answers, then tap Help Me when you're ready!")
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

    private func toggleRecording() {
        if speechRecognition.isRecording {
            speechRecognition.stopRecording()
        } else {
            Task {
                let authorized = await speechRecognition.requestAuthorization()
                if authorized {
                    speechRecognition.startRecording { transcript in
                        onStudentMessage(transcript)
                    }
                } else {
                    showMicPermissionAlert = true
                }
            }
        }
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
