import SwiftUI

enum SparkButtonStyle {
    case primary
    case secondary
    case ghost
}

struct SparkButton: View {
    let title: String
    var icon: String? = nil
    var style: SparkButtonStyle = .primary
    var isDisabled: Bool = false
    var isFullWidth: Bool = true
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            action()
        }) {
            HStack(spacing: 8) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                }
                Text(title)
                    .font(SparkTypography.bodyMedium)
            }
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(backgroundView)
            .foregroundStyle(foregroundColor)
            .clipShape(Capsule())
            .overlay(overlayView)
        }
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.5 : 1.0)
    }

    @ViewBuilder
    private var backgroundView: some View {
        switch style {
        case .primary:
            SparkTheme.teal
        case .secondary:
            Color.clear
        case .ghost:
            Color.clear
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .primary:
            return .white
        case .secondary:
            return SparkTheme.teal
        case .ghost:
            return SparkTheme.textSecondary(colorScheme)
        }
    }

    @ViewBuilder
    private var overlayView: some View {
        switch style {
        case .secondary:
            Capsule()
                .strokeBorder(SparkTheme.teal, lineWidth: 1.5)
        case .primary, .ghost:
            EmptyView()
        }
    }
}
