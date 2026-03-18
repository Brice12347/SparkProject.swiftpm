import SwiftUI
import PencilKit

struct DrawingToolbar: View {
    @Binding var selectedColor: Color
    @Binding var lineWidth: CGFloat
    @Binding var isEraser: Bool

    @Environment(\.colorScheme) private var colorScheme

    private let colors: [(Color, String)] = [
        (SparkTheme.charcoal,      "Charcoal"),
        (Color(hex: "E05C5C"),     "Red"),
        (Color(hex: "5B8AF5"),     "Blue"),
        (Color(hex: "4CAF7D"),     "Green"),
        (Color(hex: "E8A838"),     "Orange"),
        (Color(hex: "9B6BF2"),     "Purple"),
    ]

    private let widths: [(CGFloat, String)] = [
        (1.5,  "Thin"),
        (3.5,  "Medium"),
        (7.0,  "Thick"),
    ]

    var body: some View {
        HStack(spacing: 0) {
            // Pen / Eraser toggle
            toolToggle

            divider

            // Color swatches
            colorRow

            divider

            // Thickness picker
            thicknessRow
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background {
            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(.ultraThinMaterial)
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(colorScheme == .dark ? 0.18 : 0.7),
                                Color.white.opacity(colorScheme == .dark ? 0.05 : 0.2),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
        }
        .shadow(color: Color.black.opacity(0.18), radius: 16, x: 0, y: 6)
        .shadow(color: Color.black.opacity(0.06), radius: 3, x: 0, y: 1)
    }

    // MARK: - Tool Toggle

    private var toolToggle: some View {
        HStack(spacing: 6) {
            toolButton(
                icon: "pencil.tip",
                label: "Pen",
                isActive: !isEraser
            ) {
                isEraser = false
            }

            toolButton(
                icon: "eraser.line.dashed",
                label: "Erase",
                isActive: isEraser
            ) {
                isEraser = true
            }
        }
        .padding(.trailing, 14)
    }

    private func toolButton(icon: String, label: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                action()
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }) {
            VStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(isActive ? SparkTheme.teal : Color.secondary)

                Text(label)
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundStyle(isActive ? SparkTheme.teal : Color.secondary)
            }
            .frame(width: 40, height: 40)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isActive ? SparkTheme.teal.opacity(0.12) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(isActive ? SparkTheme.teal.opacity(0.4) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    // MARK: - Color Row

    private var colorRow: some View {
        HStack(spacing: 10) {
            ForEach(colors, id: \.1) { color, name in
                colorSwatch(color: color, name: name)
            }
        }
        .padding(.horizontal, 14)
    }

    private func colorSwatch(color: Color, name: String) -> some View {
        let isSelected = !isEraser && selectedColor == color
        return Button {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                selectedColor = color
                isEraser = false
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: 24, height: 24)
                    .shadow(color: color.opacity(0.4), radius: 3, x: 0, y: 2)

                if isSelected {
                    Circle()
                        .strokeBorder(color, lineWidth: 2.5)
                        .frame(width: 32, height: 32)
                }
            }
            .frame(width: 34, height: 34)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(name)
        .scaleEffect(isSelected ? 1.1 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isSelected)
    }

    // MARK: - Thickness Row

    private var thicknessRow: some View {
        HStack(spacing: 12) {
            ForEach(widths, id: \.1) { width, name in
                thicknessButton(width: width, name: name)
            }
        }
        .padding(.leading, 14)
    }

    private func thicknessButton(width: CGFloat, name: String) -> some View {
        let isSelected = !isEraser && lineWidth == width
        let dotSize = width == 1.5 ? 6.0 : width == 3.5 ? 11.0 : 17.0
        return Button {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                lineWidth = width
                isEraser = false
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            ZStack {
                Circle()
                    .fill(isSelected ? selectedColor : Color.secondary.opacity(0.5))
                    .frame(width: dotSize, height: dotSize)
            }
            .frame(width: 32, height: 32)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isSelected ? selectedColor.opacity(0.12) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(isSelected ? selectedColor.opacity(0.4) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(name)
        .scaleEffect(isSelected ? 1.1 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isSelected)
    }

    // MARK: - Divider

    private var divider: some View {
        Rectangle()
            .fill(Color.secondary.opacity(0.2))
            .frame(width: 1, height: 36)
    }
}
