import SwiftUI

struct StudentNameView: View {
    @Binding var name: String
    @Binding var avatarEmoji: String
    let accountType: AccountType
    let onContinue: () -> Void

    @FocusState private var isNameFocused: Bool
    @State private var appeared = false

    private var heading: String {
        accountType == .student ? "What's your name?" : "What's your student's name?"
    }

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 12) {
                Text(heading)
                    .font(SparkTypography.heading1)
                    .foregroundStyle(SparkTheme.charcoal)
                    .multilineTextAlignment(.center)
            }
            .opacity(appeared ? 1 : 0)

            AvatarView(emoji: avatarEmoji, size: 88)
                .scaleEffect(appeared ? 1 : 0.8)

            TextField("Your name", text: $name)
                .font(SparkTypography.heading2)
                .multilineTextAlignment(.center)
                .padding(.vertical, 16)
                .padding(.horizontal, 24)
                .background(
                    RoundedRectangle(cornerRadius: SparkTheme.radiusMD, style: .continuous)
                        .fill(SparkTheme.gray100)
                )
                .padding(.horizontal, 48)
                .focused($isNameFocused)

            VStack(spacing: 8) {
                Text("Pick an avatar")
                    .font(SparkTypography.caption)
                    .foregroundStyle(SparkTheme.gray500)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 6), spacing: 12) {
                    ForEach(avatarEmojis, id: \.self) { emoji in
                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                avatarEmoji = emoji
                            }
                        } label: {
                            Text(emoji)
                                .font(.system(size: 28))
                                .frame(width: 48, height: 48)
                                .background(
                                    Circle()
                                        .fill(avatarEmoji == emoji ? SparkTheme.teal.opacity(0.15) : SparkTheme.gray100)
                                )
                                .overlay(
                                    Circle()
                                        .strokeBorder(avatarEmoji == emoji ? SparkTheme.teal : .clear, lineWidth: 2)
                                )
                        }
                        .accessibilityLabel(emoji)
                    }
                }
                .padding(.horizontal, 32)
            }

            Spacer()

            SparkButton(title: "Continue", style: .primary) {
                onContinue()
            }
            .padding(.horizontal, 48)

            Button("Skip") {
                onContinue()
            }
            .font(SparkTypography.bodyMedium)
            .foregroundStyle(SparkTheme.gray500)

            Spacer()
                .frame(height: 20)
        }
        .padding(.horizontal, SparkTheme.spacingLG)
        .onAppear {
            withAnimation(.spring(response: 0.6).delay(0.2)) {
                appeared = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isNameFocused = true
            }
        }
    }
}
