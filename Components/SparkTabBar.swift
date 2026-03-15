import SwiftUI

enum SparkTab: String, CaseIterable {
    case home
    case homework
    case lessons
    case profile

    var title: String {
        switch self {
        case .home: return "Home"
        case .homework: return "Homework"
        case .lessons: return "Lessons"
        case .profile: return "Profile"
        }
    }

    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .homework: return "doc.text.fill"
        case .lessons: return "lightbulb.fill"
        case .profile: return "person.fill"
        }
    }
}

struct SparkTabBar: View {
    @Binding var selectedTab: SparkTab
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack {
            ForEach(SparkTab.allCases, id: \.self) { tab in
                tabButton(for: tab)
            }
        }
        .padding(.horizontal, SparkTheme.spacingMD)
        .padding(.top, 10)
        .padding(.bottom, 6)
        .background(
            SparkTheme.surface(colorScheme)
                .shadow(color: SparkTheme.cardShadow(colorScheme), radius: 8, y: -2)
        )
    }

    private func tabButton(for tab: SparkTab) -> some View {
        Button {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            selectedTab = tab
        } label: {
            VStack(spacing: 4) {
                Image(systemName: tab.icon)
                    .font(.system(size: 22))
                    .symbolRenderingMode(.hierarchical)
                Text(tab.title)
                    .font(SparkTypography.label)
            }
            .foregroundStyle(selectedTab == tab ? SparkTheme.teal : SparkTheme.gray500)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
        }
        .accessibilityLabel(tab.title)
    }
}
