import SwiftUI

struct SessionNotesSidebar: View {
    let adviceLog: [AdviceEntry]
    let onClose: () -> Void
    let onReaction: (AdviceEntry, StudentReaction) -> Void

    @State private var expandedId: UUID?
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Tutor Notes 📝")
                    .font(SparkTypography.heading2)
                    .foregroundStyle(SparkTheme.textPrimary(colorScheme))

                Spacer()

                Button {
                    onClose()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(SparkTheme.gray500)
                        .frame(width: 36, height: 36)
                        .background(SparkTheme.surfaceSecondary(colorScheme))
                        .clipShape(Circle())
                }
                .accessibilityLabel("Close sidebar")
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 12)

            Divider()

            // Advice Cards
            ScrollView {
                LazyVStack(spacing: 12) {
                    if adviceLog.isEmpty {
                        emptyState
                    } else {
                        ForEach(Array(adviceLog.enumerated()), id: \.element.id) { index, advice in
                            adviceCard(advice, isNewest: index == 0)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
        }
        .background(SparkTheme.surface(colorScheme))
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "note.text")
                .font(.system(size: 32))
                .foregroundStyle(SparkTheme.gray400)
            Text("No notes yet")
                .font(SparkTypography.bodyMedium)
                .foregroundStyle(SparkTheme.textSecondary(colorScheme))
            Text("As you work, your tutor's advice will appear here.")
                .font(SparkTypography.caption)
                .foregroundStyle(SparkTheme.gray500)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 40)
    }

    private func adviceCard(_ advice: AdviceEntry, isNewest: Bool) -> some View {
        let isExpanded = expandedId == advice.id

        return VStack(alignment: .leading, spacing: 0) {
            // Header (always visible)
            Button {
                withAnimation(.spring(response: 0.35)) {
                    expandedId = isExpanded ? nil : advice.id
                }
            } label: {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(advice.topic)
                            .font(SparkTypography.bodyMedium)
                            .foregroundStyle(SparkTheme.textPrimary(colorScheme))

                        Text(advice.formattedTime)
                            .font(SparkTypography.label)
                            .foregroundStyle(SparkTheme.gray500)

                        if !isExpanded {
                            Text(advice.summary)
                                .font(SparkTypography.caption)
                                .foregroundStyle(SparkTheme.textSecondary(colorScheme))
                                .lineLimit(2)
                        }
                    }

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(SparkTheme.gray400)
                }
            }

            // Expanded Content
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    Divider()
                        .padding(.vertical, 8)

                    Text(advice.fullAdvice)
                        .font(SparkTypography.body)
                        .foregroundStyle(SparkTheme.textPrimary(colorScheme))
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 16) {
                        reactionButton(advice: advice, reaction: .helpful, icon: "hand.thumbsup", label: "Helpful")
                        reactionButton(advice: advice, reaction: .notHelpful, icon: "hand.thumbsdown", label: "Not helpful")
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: SparkTheme.radiusMD, style: .continuous)
                .fill(SparkTheme.surface(colorScheme))
        )
        .overlay(alignment: .leading) {
            if isNewest {
                RoundedRectangle(cornerRadius: 2)
                    .fill(SparkTheme.teal)
                    .frame(width: 4)
                    .padding(.vertical, 8)
            }
        }
        .shadow(color: SparkTheme.cardShadow(colorScheme).opacity(0.5), radius: 4, y: 2)
    }

    private func reactionButton(advice: AdviceEntry, reaction: StudentReaction, icon: String, label: String) -> some View {
        let isActive = advice.studentReaction == reaction
        return Button {
            onReaction(advice, reaction)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: isActive ? "\(icon).fill" : icon)
                Text(label)
                    .font(SparkTypography.label)
            }
            .foregroundStyle(isActive ? SparkTheme.teal : SparkTheme.gray500)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule().fill(isActive ? SparkTheme.teal.opacity(0.1) : SparkTheme.surfaceSecondary(colorScheme))
            )
        }
    }
}
