import SwiftUI

struct AvatarView: View {
    let emoji: String
    var size: CGFloat = 48
    var borderColor: Color = SparkTheme.teal
    var borderWidth: CGFloat = 2.5

    var body: some View {
        Text(emoji)
            .font(.system(size: size * 0.5))
            .frame(width: size, height: size)
            .background(
                Circle()
                    .fill(SparkTheme.gray100)
            )
            .clipShape(Circle())
            .overlay(
                Circle()
                    .strokeBorder(borderColor, lineWidth: borderWidth)
            )
    }
}

let avatarEmojis: [String] = [
    "😊", "😎", "🤓", "🦊", "🐱", "🐶",
    "🦋", "🌟", "🚀", "🎨", "🎵", "📚",
    "🌈", "🦄", "🐼", "🌻", "⚡️", "🍎",
    "🎯", "💡", "🌸", "🐝", "🦉", "🎪"
]
