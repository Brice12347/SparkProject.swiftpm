import SwiftUI

struct SparkCard<Content: View>: View {
    var padding: CGFloat = SparkTheme.spacingMD
    var cornerRadius: CGFloat = SparkTheme.radiusXL
    @ViewBuilder let content: () -> Content

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        content()
            .padding(padding)
            .background(SparkTheme.surface(colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(
                color: SparkTheme.cardShadow(colorScheme),
                radius: 12,
                x: 0,
                y: 4
            )
    }
}
