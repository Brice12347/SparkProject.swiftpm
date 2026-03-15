import SwiftUI

struct AccountTypeView: View {
    @Binding var selectedType: AccountType
    let onContinue: () -> Void

    @State private var appeared = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 12) {
                Text("Who will be using Spark?")
                    .font(SparkTypography.heading1)
                    .foregroundStyle(SparkTheme.charcoal)

                Text("We'll personalize the experience for you.")
                    .font(SparkTypography.bodyLarge)
                    .foregroundStyle(SparkTheme.gray600)
            }
            .multilineTextAlignment(.center)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 15)

            VStack(spacing: 14) {
                ForEach(AccountType.allCases, id: \.self) { type in
                    accountCard(type)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 20)
                }
            }
            .padding(.horizontal, 20)

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
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2)) {
                appeared = true
            }
        }
    }

    private func accountCard(_ type: AccountType) -> some View {
        let isSelected = selectedType == type
        return Button {
            withAnimation(.spring(response: 0.3)) {
                selectedType = type
            }
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        } label: {
            HStack(spacing: 16) {
                Image(systemName: type.icon)
                    .font(.system(size: 28))
                    .foregroundStyle(isSelected ? SparkTheme.teal : SparkTheme.gray500)
                    .frame(width: 48)

                VStack(alignment: .leading, spacing: 4) {
                    Text(type.displayName)
                        .font(SparkTypography.heading3)
                        .foregroundStyle(SparkTheme.charcoal)
                    Text(type.descriptor)
                        .font(SparkTypography.caption)
                        .foregroundStyle(SparkTheme.gray600)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundStyle(isSelected ? SparkTheme.teal : SparkTheme.gray300)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: SparkTheme.radiusLG, style: .continuous)
                    .fill(.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: SparkTheme.radiusLG, style: .continuous)
                    .strokeBorder(isSelected ? SparkTheme.teal : SparkTheme.gray200, lineWidth: isSelected ? 2 : 1)
            )
        }
    }
}
