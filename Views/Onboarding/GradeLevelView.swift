import SwiftUI

struct GradeLevelView: View {
    @Binding var gradeLevel: String
    let accountType: AccountType
    let onContinue: () -> Void

    @State private var appeared = false

    private let grades = [
        "K", "1st", "2nd", "3rd", "4th", "5th", "6th",
        "7th", "8th", "9th", "10th", "11th", "12th", "College"
    ]

    private var heading: String {
        accountType == .student ? "What grade are you in?" : "What grade is your student in?"
    }

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 12) {
                Text(heading)
                    .font(SparkTypography.heading1)
                    .foregroundStyle(SparkTheme.charcoal)
                    .multilineTextAlignment(.center)

                Text("We'll match practice content and explanations to your level.")
                    .font(SparkTypography.bodyLarge)
                    .foregroundStyle(SparkTheme.gray600)
                    .multilineTextAlignment(.center)
            }
            .opacity(appeared ? 1 : 0)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(grades, id: \.self) { grade in
                        gradeChip(grade)
                    }
                }
                .padding(.horizontal, SparkTheme.spacingLG)
            }
            .opacity(appeared ? 1 : 0)

            if !gradeLevel.isEmpty {
                Text("Grade \(gradeLevel)")
                    .font(SparkTypography.heading2)
                    .foregroundStyle(SparkTheme.teal)
                    .transition(.scale.combined(with: .opacity))
            }

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

    private func gradeChip(_ grade: String) -> some View {
        let isSelected = gradeLevel == grade
        return Button {
            withAnimation(.spring(response: 0.3)) {
                gradeLevel = grade
            }
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        } label: {
            Text(grade)
                .font(SparkTypography.bodyMedium)
                .foregroundStyle(isSelected ? .white : SparkTheme.charcoal)
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
