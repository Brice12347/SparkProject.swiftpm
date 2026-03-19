import SwiftUI

struct AccountTypeGlassView: View {
    @Binding var selectedType: AccountType
    let onContinue: () -> Void

    @State private var appeared = false

    var body: some View {
        GeometryReader { geo in
            let cardWidth = min(geo.size.width * 0.84, 860)

            ZStack {
                Color.white.ignoresSafeArea()

                VStack(spacing: 0) {
                    Spacer(minLength: 28)

                    VStack(spacing: 26) {
                        VStack(spacing: 10) {
                            Text("Who will be using Spark?")
                                .font(.system(size: 38, weight: .bold, design: .default))
                                .foregroundStyle(SparkTheme.charcoal)
                                .padding(.bottom, 10)

                            Text("We'll personalize the experience for you.")
                                .font(.system(size: 20, weight: .regular, design: .default))
                                .foregroundStyle(SparkTheme.gray600)
                                .padding(.bottom, 122)
                        }
                        .multilineTextAlignment(.center)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 15)

                        VStack(spacing: 18) {
                            ForEach(AccountType.allCases, id: \.self) { type in
                                accountCard(type)
                                    .opacity(appeared ? 1 : 0)
                                    .offset(y: appeared ? 0 : 20)
                            }
                        }

                        Spacer(minLength: 26)

                        ContinueButton(action: onContinue)
                            .padding(.horizontal, 22)
                            .padding(.top, 20)
                    }
                    .padding(.horizontal, 34)
                    .padding(.top, 42)
                    .padding(.bottom, 34)
                    .frame(width: cardWidth)

                    Spacer(minLength: 34)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
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
            HStack(spacing: 22) {
                Image(systemName: type.icon)
                    .font(.system(size: 38, weight: .regular))
                    .foregroundStyle(isSelected ? SparkTheme.teal : SparkTheme.gray500)
                    .frame(width: 72)

                VStack(alignment: .leading, spacing: 8) {
                    Text(type.displayName)
                        .font(.system(size: 28, weight: .bold, design: .default))
                        .foregroundStyle(SparkTheme.charcoal)
                    Text(type.descriptor)
                        .font(.system(size: 20, weight: .regular, design: .default))
                        .foregroundStyle(SparkTheme.gray600)
                        .lineLimit(type == .student ? 1 : nil)
                        .minimumScaleFactor(type == .student ? 0.92 : 1.0)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 14)

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(isSelected ? SparkTheme.teal : SparkTheme.gray300)
                    .padding(.trailing, 4)
            }
            .padding(.vertical, 24)
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(
                        isSelected
                        ? LinearGradient(
                            colors: [
                                SparkTheme.teal.opacity(0.24),
                                SparkTheme.teal.opacity(0.12),
                                .white.opacity(0.20)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        : LinearGradient(
                            colors: [Color.white, Color.white],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay {
                        if isSelected {
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .fill(.ultraThinMaterial)
                                .opacity(0.62)
                        }
                    }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(
                        isSelected ? SparkTheme.teal.opacity(0.70) : SparkTheme.gray200,
                        lineWidth: isSelected ? 1.8 : 1
                    )
            )
            .glassIfAvailable(
                isEnabled: isSelected,
                shape: RoundedRectangle(cornerRadius: 24, style: .continuous)
            )
            .shadow(color: .black.opacity(isSelected ? 0.09 : 0.03), radius: isSelected ? 16 : 8, y: 6)
        }
        .buttonStyle(.plain)
    }
}

private struct ContinueButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("Continue")
                .font(.system(size: 20, weight: .bold, design: .default))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 60)
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
        .shadow(color: SparkTheme.teal.opacity(0.24), radius: 16, y: 8)
    }
}
