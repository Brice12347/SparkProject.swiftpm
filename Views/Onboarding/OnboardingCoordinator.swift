import SwiftUI
import SwiftData

struct OnboardingCoordinator: View {
    @Environment(\.modelContext) private var modelContext
    @State private var currentStep = 0
    @State private var accountType: AccountType = .student
    @State private var studentName: String = ""
    @State private var avatarEmoji: String = "😊"
    @State private var gradeLevel: String = "5th"
    @State private var selectedSubjects: Set<Subject> = []
    @State private var learningStyleTags: Set<String> = []
    @State private var reminderTime: Date = {
        var components = DateComponents()
        components.hour = 16
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }()
    @State private var notificationsEnabled = false
    @State private var showCompletion = false

    let onComplete: () -> Void

    private let totalSteps = 8

    var body: some View {
        ZStack {
            backgroundGradient

            VStack(spacing: 0) {
                progressBar
                    .padding(.top, 8)

                TabView(selection: $currentStep) {
                    WelcomeView(onContinue: nextStep)
                        .tag(0)

                    AccountTypeGlassView(selectedType: $accountType, onContinue: nextStep)
                        .tag(1)

                    StudentNameView(
                        name: $studentName,
                        avatarEmoji: $avatarEmoji,
                        accountType: accountType,
                        onContinue: nextStep
                    )
                    .tag(2)

                    GradeLevelView(
                        gradeLevel: $gradeLevel,
                        accountType: accountType,
                        onContinue: nextStep
                    )
                    .tag(3)

                    LearningFocusView(
                        selectedSubjects: $selectedSubjects,
                        onContinue: nextStep
                    )
                    .tag(4)

                    LearningStyleView(
                        selectedTags: $learningStyleTags,
                        onContinue: nextStep
                    )
                    .tag(5)

                    MeetTutorView(onContinue: nextStep)
                        .tag(6)

                    DailyReminderView(
                        reminderTime: $reminderTime,
                        notificationsEnabled: $notificationsEnabled,
                        onComplete: completeOnboarding
                    )
                    .tag(7)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.4), value: currentStep)
            }

            if showCompletion {
                completionOverlay
                    .transition(.opacity)
            }
        }
    }

    private var backgroundGradient: some View {
        Color.white
            .ignoresSafeArea()
    }

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(SparkTheme.gray200)
                    .frame(height: 3)

                Rectangle()
                    .fill(SparkTheme.teal)
                    .frame(width: geo.size.width * CGFloat(currentStep + 1) / CGFloat(totalSteps), height: 3)
                    .animation(.spring(response: 0.5), value: currentStep)
            }
        }
        .frame(height: 3)
        .padding(.horizontal, SparkTheme.spacingLG)
    }

    private var completionOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Text("✦")
                    .font(.system(size: 60))
                    .foregroundStyle(SparkTheme.teal)

                Text("Your Spark journey starts now.")
                    .font(SparkTypography.heading1)
                    .foregroundStyle(SparkTheme.charcoal)
                    .multilineTextAlignment(.center)
            }
            .padding(40)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: SparkTheme.radiusXXL, style: .continuous))

            ConfettiView()
                .ignoresSafeArea()
        }
    }

    private func nextStep() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            currentStep = min(currentStep + 1, totalSteps - 1)
        }
    }

    private func completeOnboarding() {
        let student = Student(
            name: studentName.isEmpty ? "Learner" : studentName,
            gradeLevel: gradeLevel,
            avatarEmoji: avatarEmoji
        )
        student.subjectPreferences = Array(selectedSubjects)
        student.learningStyleTags = Array(learningStyleTags)
        student.dailyReminderTime = reminderTime
        student.notificationsEnabled = notificationsEnabled
        student.onboardingAnswers = OnboardingAnswers(
            accountType: accountType.rawValue,
            gradeLevel: gradeLevel,
            subjects: selectedSubjects.map(\.rawValue),
            learningStyleTags: Array(learningStyleTags),
            reminderTime: reminderTime,
            notificationsEnabled: notificationsEnabled
        )

        modelContext.insert(student)
        try? modelContext.save()

        withAnimation(.easeIn(duration: 0.4)) {
            showCompletion = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            onComplete()
        }
    }
}
