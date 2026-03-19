import SwiftUI

struct SparkTabBarCodex: View {
    @Binding var selectedTab: SparkTab
    @Environment(\.colorScheme) private var colorScheme

    private let barCornerRadius: CGFloat = 30

    var body: some View {
        HStack(spacing: 8) {
            ForEach(SparkTab.allCases, id: \.self) { tab in
                tabButton(for: tab)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background {
            RoundedRectangle(cornerRadius: barCornerRadius, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: barCornerRadius, style: .continuous)
                        .fill(glassTint)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: barCornerRadius, style: .continuous)
                        .strokeBorder(glassStroke, lineWidth: 1)
                }
        }
        .shadow(color: shadowColor, radius: 22, y: 12)
        .shadow(color: shadowColor.opacity(0.4), radius: 8, y: 2)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    private func tabButton(for tab: SparkTab) -> some View {
        let isSelected = selectedTab == tab

        return Button {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                selectedTab = tab
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: tab.icon)
                    .font(.system(size: 20, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
                Text(tab.title)
                    .font(.system(size: 13, weight: .semibold, design: .default))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .foregroundStyle(isSelected ? selectedForeground : unselectedForeground)
            .frame(maxWidth: .infinity)
            .frame(height: 58)
            .background {
                if isSelected {
                    Capsule(style: .continuous)
                        .fill(.thinMaterial)
                        .overlay {
                            Capsule(style: .continuous)
                                .fill(selectedFillTint)
                        }
                        .overlay {
                            Capsule(style: .continuous)
                                .strokeBorder(selectedStroke, lineWidth: 1)
                        }
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.title)
    }

    // MARK: - Adaptive Styling

    private var glassTint: Color {
        colorScheme == .dark ? .white.opacity(0.08) : .white.opacity(0.32)
    }

    private var glassStroke: Color {
        colorScheme == .dark ? .white.opacity(0.22) : .white.opacity(0.62)
    }

    private var selectedFillTint: Color {
        SparkTheme.teal.opacity(colorScheme == .dark ? 0.28 : 0.18)
    }

    private var selectedStroke: Color {
        colorScheme == .dark ? .white.opacity(0.28) : .white.opacity(0.72)
    }

    private var selectedForeground: Color {
        colorScheme == .dark ? .white : SparkTheme.teal
    }

    private var unselectedForeground: Color {
        SparkTheme.gray500
    }

    private var shadowColor: Color {
        colorScheme == .dark ? .black.opacity(0.5) : .black.opacity(0.18)
    }
}
