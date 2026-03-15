import SwiftUI

struct LearningFocusView: View {
    @Binding var selectedSubjects: Set<Subject>
    let onContinue: () -> Void

    @State private var appeared = false

    private let subjects: [(Subject, String)] = [
        (.math, "📐 Math"),
        (.reading, "📖 Reading & Writing"),
        (.science, "🔬 Science"),
        (.history, "🌍 History & Social Studies"),
        (.foreignLanguage, "🗣️ Foreign Language"),
        (.other, "✏️ Other")
    ]

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 12) {
                Text("What subjects would you\nlike help with?")
                    .font(SparkTypography.heading1)
                    .foregroundStyle(SparkTheme.charcoal)
                    .multilineTextAlignment(.center)

                Text("Choose all that apply — we'll set them up in your app.")
                    .font(SparkTypography.bodyLarge)
                    .foregroundStyle(SparkTheme.gray600)
                    .multilineTextAlignment(.center)
            }
            .opacity(appeared ? 1 : 0)

            FlowLayout(spacing: 12) {
                ForEach(subjects, id: \.0) { subject, display in
                    subjectPill(subject: subject, display: display)
                }
            }
            .padding(.horizontal, 24)
            .opacity(appeared ? 1 : 0)

            Spacer()

            SparkButton(
                title: "Continue",
                style: .primary,
                isDisabled: selectedSubjects.isEmpty
            ) {
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

    private func subjectPill(subject: Subject, display: String) -> some View {
        let isSelected = selectedSubjects.contains(subject)
        return Button {
            withAnimation(.spring(response: 0.3)) {
                if isSelected {
                    selectedSubjects.remove(subject)
                } else {
                    selectedSubjects.insert(subject)
                }
            }
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        } label: {
            Text(display)
                .font(SparkTypography.bodyMedium)
                .foregroundStyle(isSelected ? .white : SparkTheme.charcoal)
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(
                    Capsule().fill(isSelected ? SparkTheme.teal : .white)
                )
                .overlay(
                    Capsule().strokeBorder(isSelected ? SparkTheme.teal : SparkTheme.gray200, lineWidth: 1.5)
                )
        }
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(in: proposal.width ?? 0, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(in: bounds.width, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: .unspecified
            )
        }
    }

    private func layout(in width: CGFloat, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var maxHeight: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > width && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            maxHeight = max(maxHeight, y + rowHeight)
        }

        return (CGSize(width: width, height: maxHeight), positions)
    }
}
