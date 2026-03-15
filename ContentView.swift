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

struct MainTabView: View {
    let student: Student
    @State private var selectedTab: SparkTab = .home
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 0) {
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

            SparkTabBar(selectedTab: $selectedTab)
        }
        .background(SparkTheme.background(colorScheme).ignoresSafeArea())
        .ignoresSafeArea(.keyboard)
    }
}
