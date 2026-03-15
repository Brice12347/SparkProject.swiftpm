import Foundation
import SwiftData

@Model
final class Student {
    var id: UUID
    var name: String
    var gradeLevel: String
    var avatarEmoji: String
    var subjectPreferencesRaw: [String]
    var learningStyleTags: [String]
    var preferredVoiceSpeedRaw: String
    var dailyReminderTime: Date?
    var notificationsEnabled: Bool
    var onboardingAnswersData: Data?
    var teacherLinkCode: String?
    var streakCount: Int
    var streakFreezeUsed: Bool
    var lastSessionDate: Date?
    var createdAt: Date
    var appearanceModeRaw: String
    var textSizeRaw: String
    var useDyslexicFont: Bool
    var highContrastEnabled: Bool
    var reduceMotionEnabled: Bool
    var claudeAPIKey: String?

    init(
        name: String = "Learner",
        gradeLevel: String = "5th",
        avatarEmoji: String = "😊"
    ) {
        self.id = UUID()
        self.name = name
        self.gradeLevel = gradeLevel
        self.avatarEmoji = avatarEmoji
        self.subjectPreferencesRaw = []
        self.learningStyleTags = []
        self.preferredVoiceSpeedRaw = VoiceSpeed.normal.rawValue
        self.notificationsEnabled = false
        self.streakCount = 0
        self.streakFreezeUsed = false
        self.createdAt = Date()
        self.appearanceModeRaw = AppearanceMode.system.rawValue
        self.textSizeRaw = SparkTypography.TextSize.default.rawValue
        self.useDyslexicFont = false
        self.highContrastEnabled = false
        self.reduceMotionEnabled = false
    }

    var subjectPreferences: [Subject] {
        get { subjectPreferencesRaw.compactMap { Subject(rawValue: $0) } }
        set { subjectPreferencesRaw = newValue.map(\.rawValue) }
    }

    var preferredVoiceSpeed: VoiceSpeed {
        get { VoiceSpeed(rawValue: preferredVoiceSpeedRaw) ?? .normal }
        set { preferredVoiceSpeedRaw = newValue.rawValue }
    }

    var appearanceMode: AppearanceMode {
        get { AppearanceMode(rawValue: appearanceModeRaw) ?? .system }
        set { appearanceModeRaw = newValue.rawValue }
    }

    var textSize: SparkTypography.TextSize {
        get { SparkTypography.TextSize(rawValue: textSizeRaw) ?? .default }
        set { textSizeRaw = newValue.rawValue }
    }

    var onboardingAnswers: OnboardingAnswers? {
        get {
            guard let data = onboardingAnswersData else { return nil }
            return try? JSONDecoder().decode(OnboardingAnswers.self, from: data)
        }
        set {
            onboardingAnswersData = try? JSONEncoder().encode(newValue)
        }
    }

    var todayHasSession: Bool {
        guard let lastDate = lastSessionDate else { return false }
        return Calendar.current.isDateInToday(lastDate)
    }
}

struct OnboardingAnswers: Codable {
    var accountType: String
    var gradeLevel: String
    var subjects: [String]
    var learningStyleTags: [String]
    var reminderTime: Date?
    var notificationsEnabled: Bool
}
