import SwiftUI
import SwiftData

struct ContentView: View {
    @Query private var students: [Student]
    @State private var hasCompletedOnboarding = false

    var body: some View {
        Group {
            if let student = students.first, hasCompletedOnboarding {
                MainTabView(student: student)
                    .transition(.opacity)
            } else if students.first != nil {
                Color.clear
                    .onAppear { hasCompletedOnboarding = true }
            } else {
                OnboardingCoordinator {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.85)) {
                        hasCompletedOnboarding = true
                    }
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: hasCompletedOnboarding)
        .onAppear {
            if students.first != nil {
                hasCompletedOnboarding = true
            }
        }
    }
}

// DEBUG: 1. Define an enum for your tab bar versions
enum TabBarVersion: String, CaseIterable {
    case original = "Original"
    case gemini = "Gemini"
    case codex = "Codex"
}

struct MainTabView: View {
    let student: Student
    @State private var selectedTab: SparkTab = .home
    @Environment(\.colorScheme) private var colorScheme
    
    // DEBUG: 2. Add a state variable to track the currently selected version
    @State private var currentTabBarVersion: TabBarVersion = .gemini

    var body: some View {
        VStack(spacing: 0) {
            // --- DEBUG UI: VERSION TOGGLE ---
            // A segmented picker at the top to easily switch between styles
            Picker("Tab Bar Version", selection: $currentTabBarVersion) {
                ForEach(TabBarVersion.allCases, id: \.self) { version in
                    Text(version.rawValue).tag(version)
                }
            }
            .pickerStyle(.segmented)
            .padding()
            .background(SparkTheme.surface(colorScheme))
            .zIndex(1) // Keeps it above the content
            // ---------------------------------

            Group {
                switch selectedTab {
                case .home:
                    NavigationStack {
                        HomeDashboardView(student: student)
                    }
                case .homework:
                    NavigationStack {
                        HomeworkUploadView(student: student)
                    }
                case .lessons:
                    NavigationStack {
                        LessonListView(student: student)
                    }
                case .profile:
                    NavigationStack {
                        StudentProfileView(student: student)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // DEBUG: 3. The Switch Statement to swap out the bottom bar
            switch currentTabBarVersion {
            case .original:
                SparkTabBar(selectedTab: $selectedTab)
            case .gemini:
                SparkTabBarGemini(selectedTab: $selectedTab)
            case .codex:
                SparkTabBarCodex(selectedTab: $selectedTab)
            }
        }
        .background(SparkTheme.background(colorScheme).ignoresSafeArea())
        .ignoresSafeArea(.keyboard)
    }
}
