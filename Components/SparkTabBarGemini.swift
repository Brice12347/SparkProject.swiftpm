import SwiftUI

struct SparkTabBarGemini: View {
    @Binding var selectedTab: SparkTab
    @Environment(\.colorScheme) private var colorScheme
    
    // NEW: Define the colors that should change based on mode here
    private var activeColor: Color {
        // The image shows purple, but you mentioned teal. I'll stick to teal here for your brand consistency.
        // Change SparkTheme.teal below to the specific purple if that's mandatory.
        return SparkTheme.teal
    }
    
    // Inactive labels are gray in Light, white in Dark for better contrast on glass
    private var inactiveColor: Color {
        return colorScheme == .dark ? Color.white : SparkTheme.gray500
    }

    var body: some View {
        HStack(spacing: 0) { // Keep items tightly aligned
            ForEach(SparkTab.allCases, id: \.self) { tab in
                tabButton(for: tab)
            }
        }
        .frame(height: 72) // Specific height for the bar itself
        .padding(.horizontal, 10) // Small inner padding before the buttons start
        
        // --- THE "GLASS" BACKGROUND (CONTAINER) ---
        .background(
            Capsule()
                // Base blur + background tint
                .fill(SparkTheme.surface(colorScheme))
                .overlay(
                    // 1. That "raised/beveled" look requires an INNER GLOW/SHADOW.
                    // We simulate this by overlaying a gradient Capsule.
                    Capsule()
                        // Fade white light from the top-left edge
                        .fill(LinearGradient(stops: [
                            .init(color: .white.opacity(colorScheme == .dark ? 0.35 : 0.1), location: 0),
                            .init(color: .white.opacity(0), location: 0.15), // Fade it out quickly
                            .init(color: .black.opacity(colorScheme == .dark ? 0.05 : 0), location: 0.9) // Subtlest hint of shadow at the bottom
                        ], startPoint: .topLeading, endPoint: .bottomTrailing))
                )
                .background(
                    // 2. The core "Glass" blur effect
                    Capsule()
                        .fill(.ultraThinMaterial)
                        // Add some noise/color in dark mode if needed
                        .environment(\.colorScheme, colorScheme)
                )
        )
        // Add a standard card shadow for depth
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.1), radius: 10, y: 5)
        
        // --- MAKIND IT FLOAT ---
        // Give the entire control some breathing room from the screen edge
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
        
        // Ensure it always sits above the keyboard without resizing strangely
        .ignoresSafeArea(.keyboard)
    }

    private func tabButton(for tab: SparkTab) -> some View {
        Button {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                selectedTab = tab
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: tab.icon)
                    .font(.system(size: 20)) // Match icon size
                Text(tab.title)
                    .font(SparkTypography.label)
                    .fontWeight(.medium) // Define label style
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .foregroundStyle(selectedTab == tab ? activeColor : inactiveColor)
        
        // --- NEW: THE GLASSY OVERLAY FOR ACTIVE TAB ---
        .background(
            Group {
                if selectedTab == tab {
                    // Match the specific shape of the active highlight in the reference image
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .fill(.white.opacity(colorScheme == .dark ? 0.1 : 0.4))
                        .overlay(
                            RoundedRectangle(cornerRadius: 30, style: .continuous)
                                .fill(LinearGradient(colors: [
                                    .white.opacity(colorScheme == .dark ? 0.3 : 0.0),
                                    .white.opacity(0.0)
                                ], startPoint: .topLeading, endPoint: .bottomTrailing))
                        )
                        // Subtle inner padding around the highlight
                        .padding(.horizontal, 4)
                        .padding(.vertical, 10)
                        .matchedGeometryEffect(id: "activeTabBackground", in: animationNamespace)
                }
            }
        )
        .accessibilityLabel(tab.title)
    }
    
    // MatchedGeometryEffect for smooth animation across tabs
    @Namespace private var animationNamespace
}

// Preview Provider updated with light and dark samples
#Preview {
    ZStack(alignment: .bottom) {
        // Sample homepage background (dark gradient)
        LinearGradient(colors: [Color.black, Color.init(white: 0.1)], startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
        
        // Placeholder text/content
        ScrollView {
            VStack(spacing: 20) {
                ForEach(0..<20) { i in
                    Text("Placeholder content row \(i)")
                        .frame(maxWidth: .infinity)
                        .frame(height: 100)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(12)
                }
            }
            .padding()
            .padding(.bottom, 100) // Ensure content doesn't get hidden behind the floating bar
        }
        
        // The dynamic tab bar
        SparkTabBar(selectedTab: .constant(.home))
    }
    .preferredColorScheme(.dark)
}

#Preview("Light Mode") {
    ZStack(alignment: .bottom) {
        Color.white.ignoresSafeArea() // Light Mode Background
        
        // Placeholder text/content
        ScrollView {
            VStack(spacing: 20) {
                ForEach(0..<20) { i in
                    Text("Placeholder content row \(i)")
                        .frame(maxWidth: .infinity)
                        .frame(height: 100)
                        .background(Color.black.opacity(0.02))
                        .cornerRadius(12)
                }
            }
            .padding()
            .padding(.bottom, 100)
        }
        
        // In the preview we can't easily change the binding, so we show different selected tabs
        SparkTabBar(selectedTab: .constant(.homework))
    }
    .preferredColorScheme(.light)
}
