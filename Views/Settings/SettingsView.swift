import SwiftUI
import SwiftData

struct SettingsView: View {
    let student: Student
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var name: String = ""
    @State private var gradeLevel: String = ""
    @State private var avatarEmoji: String = ""
    @State private var voiceSpeed: VoiceSpeed = .normal
    @State private var appearanceMode: AppearanceMode = .system
    @State private var textSize: SparkTypography.TextSize = .default
    @State private var useDyslexicFont: Bool = false
    @State private var highContrast: Bool = false
    @State private var reduceMotion: Bool = false
    @State private var apiKey: String = ""
    @State private var showResetAlert = false
    @State private var dailyReminderTime: Date = Date()
    @State private var notificationsEnabled: Bool = false

    var body: some View {
        NavigationStack {
            Form {
                profileSection
                dailyGoalSection
                aiTutorSection
                appearanceSection
                accessibilitySection
                notificationsSection
                dataSection
                aboutSection
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        saveChanges()
                        dismiss()
                    }
                    .font(SparkTypography.bodyMedium)
                    .foregroundStyle(SparkTheme.teal)
                }
            }
            .onAppear(perform: loadSettings)
            .alert("Reset Progress", isPresented: $showResetAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) { resetProgress() }
            } message: {
                Text("This will delete all session history, lesson plans, and concept profiles. This cannot be undone.")
            }
        }
    }

    // MARK: - Profile

    private var profileSection: some View {
        Section("Profile") {
            HStack {
                Text("Name")
                Spacer()
                TextField("Name", text: $name)
                    .multilineTextAlignment(.trailing)
                    .foregroundStyle(SparkTheme.textSecondary(colorScheme))
            }

            HStack {
                Text("Grade Level")
                Spacer()
                Text(gradeLevel)
                    .foregroundStyle(SparkTheme.textSecondary(colorScheme))
            }

            HStack {
                Text("Avatar")
                Spacer()
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(avatarEmojis.prefix(12), id: \.self) { emoji in
                            Button {
                                avatarEmoji = emoji
                            } label: {
                                Text(emoji)
                                    .font(.system(size: 24))
                                    .frame(width: 36, height: 36)
                                    .background(
                                        Circle().fill(avatarEmoji == emoji ? SparkTheme.teal.opacity(0.15) : Color.clear)
                                    )
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Daily Goal

    private var dailyGoalSection: some View {
        Section("Daily Goal") {
            DatePicker("Study Reminder", selection: $dailyReminderTime, displayedComponents: .hourAndMinute)

            Toggle("Notifications", isOn: $notificationsEnabled)
                .tint(SparkTheme.teal)
        }
    }

    // MARK: - AI Tutor

    private var aiTutorSection: some View {
        Section("AI Tutor") {
            Picker("Voice Speed", selection: $voiceSpeed) {
                ForEach(VoiceSpeed.allCases, id: \.self) { speed in
                    Text(speed.displayName).tag(speed)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Claude API Key")
                SecureField("sk-ant-...", text: $apiKey)
                    .font(.system(.body, design: .monospaced))
                    .textContentType(.password)
            }
        }
    }

    // MARK: - Appearance

    private var appearanceSection: some View {
        Section("Appearance") {
            Picker("Theme", selection: $appearanceMode) {
                ForEach(AppearanceMode.allCases, id: \.self) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }

            Picker("Text Size", selection: $textSize) {
                ForEach(SparkTypography.TextSize.allCases, id: \.self) { size in
                    Text(size.rawValue.capitalized).tag(size)
                }
            }

            Toggle("Dyslexia-Friendly Font", isOn: $useDyslexicFont)
                .tint(SparkTheme.teal)
        }
    }

    // MARK: - Accessibility

    private var accessibilitySection: some View {
        Section("Accessibility") {
            Toggle("High Contrast", isOn: $highContrast)
                .tint(SparkTheme.teal)

            Toggle("Reduce Motion", isOn: $reduceMotion)
                .tint(SparkTheme.teal)
        }
    }

    // MARK: - Notifications

    private var notificationsSection: some View {
        Section("Notifications") {
            Text("Daily study reminder")
                .font(SparkTypography.body)
            Text("Streak at risk alerts")
                .font(SparkTypography.body)
            Text("New lesson ready")
                .font(SparkTypography.body)
        }
    }

    // MARK: - Data

    private var dataSection: some View {
        Section("Data") {
            Button("Reset Progress") {
                showResetAlert = true
            }
            .foregroundStyle(.red)
        }
    }

    // MARK: - About

    private var aboutSection: some View {
        Section("About") {
            HStack {
                Text("Version")
                Spacer()
                Text("1.0.0")
                    .foregroundStyle(SparkTheme.textSecondary(colorScheme))
            }
            HStack {
                Text("Build")
                Spacer()
                Text("1")
                    .foregroundStyle(SparkTheme.textSecondary(colorScheme))
            }
        }
    }

    // MARK: - Actions

    private func loadSettings() {
        name = student.name
        gradeLevel = student.gradeLevel
        avatarEmoji = student.avatarEmoji
        voiceSpeed = student.preferredVoiceSpeed
        appearanceMode = student.appearanceMode
        textSize = student.textSize
        useDyslexicFont = student.useDyslexicFont
        highContrast = student.highContrastEnabled
        reduceMotion = student.reduceMotionEnabled
        apiKey = student.claudeAPIKey ?? ""
        dailyReminderTime = student.dailyReminderTime ?? Date()
        notificationsEnabled = student.notificationsEnabled
    }

    private func saveChanges() {
        student.name = name
        student.avatarEmoji = avatarEmoji
        student.preferredVoiceSpeed = voiceSpeed
        student.appearanceMode = appearanceMode
        student.textSize = textSize
        student.useDyslexicFont = useDyslexicFont
        student.highContrastEnabled = highContrast
        student.reduceMotionEnabled = reduceMotion
        student.claudeAPIKey = apiKey.isEmpty ? nil : apiKey
        student.dailyReminderTime = dailyReminderTime
        student.notificationsEnabled = notificationsEnabled

        // Apply typography settings globally
        SparkTypography.useDyslexicFont = useDyslexicFont
        SparkTypography.textSize = textSize

        // Update speech service
        SpeechService.shared.setSpeed(voiceSpeed)

        // Update API key
        if !apiKey.isEmpty {
            Task {
                await ClaudeAPIClient.shared.setAPIKey(apiKey)
            }
        }

        // Update notifications
        if notificationsEnabled {
            NotificationService.shared.scheduleDailyReminder(at: dailyReminderTime)
            NotificationService.shared.scheduleStreakAtRisk()
        } else {
            NotificationService.shared.removeAll()
        }

        try? modelContext.save()
    }

    private func resetProgress() {
        deleteAll(HomeworkSession.self, studentId: student.id)
        deleteAll(AdviceEntry.self, studentId: student.id)
        deleteAll(ConceptProfile.self, studentId: student.id)
        deleteAll(LessonPlan.self, studentId: student.id)

        student.streakCount = 0
        student.lastSessionDate = nil

        try? modelContext.save()
    }

    private func deleteAll<T: PersistentModel>(_ type: T.Type, studentId: UUID) where T: HasStudentId {
        let descriptor = FetchDescriptor<T>(predicate: T.predicateForStudent(studentId))
        if let results = try? modelContext.fetch(descriptor) {
            results.forEach { modelContext.delete($0) }
        }
    }
}

protocol HasStudentId: PersistentModel {
    var studentId: UUID { get }
    static func predicateForStudent(_ id: UUID) -> Predicate<Self>
}

extension HomeworkSession: HasStudentId {
    static func predicateForStudent(_ id: UUID) -> Predicate<HomeworkSession> {
        #Predicate { $0.studentId == id }
    }
}

extension AdviceEntry: HasStudentId {
    static func predicateForStudent(_ id: UUID) -> Predicate<AdviceEntry> {
        #Predicate { $0.studentId == id }
    }
}

extension ConceptProfile: HasStudentId {
    static func predicateForStudent(_ id: UUID) -> Predicate<ConceptProfile> {
        #Predicate { $0.studentId == id }
    }
}

extension LessonPlan: HasStudentId {
    static func predicateForStudent(_ id: UUID) -> Predicate<LessonPlan> {
        #Predicate { $0.studentId == id }
    }
}
