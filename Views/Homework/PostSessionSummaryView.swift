import SwiftUI

struct PostSessionSummaryView: View {
    let session: HomeworkSession?
    let adviceLog: [AdviceEntry]
    let onDismiss: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @State private var showConfetti = false
    @State private var appeared = false
    @State private var showNotes = false

    var body: some View {
        ZStack {
            SparkTheme.background(colorScheme).ignoresSafeArea()

            ScrollView {
                VStack(spacing: SparkTheme.spacingLG) {
                    Spacer(minLength: 40)

                    // Header
                    VStack(spacing: 12) {
                        Text("✦")
                            .font(.system(size: 48))
                            .foregroundStyle(SparkTheme.teal)

                        Text("Session complete!")
                            .font(SparkTypography.heading1)
                            .foregroundStyle(SparkTheme.textPrimary(colorScheme))
                    }
                    .scaleEffect(appeared ? 1 : 0.9)
                    .opacity(appeared ? 1 : 0)

                    // Stats Row
                    statsRow
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 15)

                    // Concept Tags
                    if let session, !session.conceptsIdentified.isEmpty {
                        conceptTags(session)
                            .opacity(appeared ? 1 : 0)
                    }

                    // Actions
                    VStack(spacing: 12) {
                        SparkButton(title: "Review Session Notes", icon: "doc.text", style: .secondary) {
                            showNotes = true
                        }

                        if let topStruggle = session?.conceptsStruggles.first {
                            SparkButton(title: "Start a Lesson on \(topStruggle)", icon: "lightbulb.fill", style: .primary) {
                                onDismiss()
                            }
                        }

                        SparkButton(title: "Back to Home", style: .ghost) {
                            onDismiss()
                        }
                    }
                    .padding(.horizontal, 24)
                    .opacity(appeared ? 1 : 0)

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, SparkTheme.spacingMD)
            }

            if showConfetti {
                ConfettiView()
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
        }
        .sheet(isPresented: $showNotes) {
            notesSheet
        }
        .onAppear {
            showConfetti = true
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)

            withAnimation(.spring(response: 0.7, dampingFraction: 0.75).delay(0.3)) {
                appeared = true
            }
        }
    }

    // MARK: - Stats

    private var statsRow: some View {
        HStack(spacing: 0) {
            statItem(value: session?.formattedDuration ?? "—", label: "Duration")
            divider
            statItem(value: "\(session?.conceptsIdentified.count ?? 0)", label: "Concepts")
            divider
            statItem(value: "\(adviceLog.count)", label: "Tutor Tips")
        }
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: SparkTheme.radiusLG, style: .continuous)
                .fill(SparkTheme.surface(colorScheme))
        )
        .shadow(color: SparkTheme.cardShadow(colorScheme), radius: 8, y: 2)
    }

    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(SparkTypography.heading2)
                .foregroundStyle(SparkTheme.teal)
            Text(label)
                .font(SparkTypography.caption)
                .foregroundStyle(SparkTheme.textSecondary(colorScheme))
        }
        .frame(maxWidth: .infinity)
    }

    private var divider: some View {
        Rectangle()
            .fill(SparkTheme.gray200)
            .frame(width: 1, height: 40)
    }

    // MARK: - Concept Tags

    private func conceptTags(_ session: HomeworkSession) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Concepts Covered")
                .font(SparkTypography.heading3)
                .foregroundStyle(SparkTheme.textPrimary(colorScheme))

            FlowLayout(spacing: 8) {
                ForEach(session.conceptsStrengths, id: \.self) { concept in
                    conceptPill(concept, color: SparkTheme.strengthGreen)
                }
                ForEach(session.conceptsStruggles, id: \.self) { concept in
                    conceptPill(concept, color: SparkTheme.struggleRed)
                }
                ForEach(session.conceptsIdentified.filter {
                    !session.conceptsStrengths.contains($0) && !session.conceptsStruggles.contains($0)
                }, id: \.self) { concept in
                    conceptPill(concept, color: SparkTheme.practiceAmber)
                }
            }
        }
        .padding(.horizontal, 8)
    }

    private func conceptPill(_ concept: String, color: Color) -> some View {
        Text(concept)
            .font(SparkTypography.captionBold)
            .foregroundStyle(color)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }

    // MARK: - Notes Sheet

    private var notesSheet: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 14) {
                    ForEach(adviceLog, id: \.id) { advice in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(advice.topic)
                                    .font(SparkTypography.bodyMedium)
                                Spacer()
                                Text(advice.formattedTime)
                                    .font(SparkTypography.label)
                                    .foregroundStyle(SparkTheme.gray500)
                            }
                            Text(advice.fullAdvice)
                                .font(SparkTypography.body)
                                .foregroundStyle(SparkTheme.textSecondary(colorScheme))
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: SparkTheme.radiusMD, style: .continuous)
                                .fill(SparkTheme.surface(colorScheme))
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("Session Notes")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
