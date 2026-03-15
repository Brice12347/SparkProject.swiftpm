import Foundation

enum Subject: String, Codable, CaseIterable, Identifiable {
    case math
    case reading
    case writing
    case science
    case history
    case foreignLanguage
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .math: return "Math"
        case .reading: return "Reading & Writing"
        case .writing: return "Writing"
        case .science: return "Science"
        case .history: return "History & Social Studies"
        case .foreignLanguage: return "Foreign Language"
        case .other: return "Other"
        }
    }

    var icon: String {
        switch self {
        case .math: return "📐"
        case .reading: return "📖"
        case .writing: return "✏️"
        case .science: return "🔬"
        case .history: return "🌍"
        case .foreignLanguage: return "🗣️"
        case .other: return "📝"
        }
    }

    var sfSymbol: String {
        switch self {
        case .math: return "function"
        case .reading: return "book.fill"
        case .writing: return "pencil.line"
        case .science: return "flask.fill"
        case .history: return "globe.americas.fill"
        case .foreignLanguage: return "bubble.left.and.text.bubble.right.fill"
        case .other: return "doc.text.fill"
        }
    }
}

enum PerformanceTag: String, Codable {
    case great
    case keepPracticing
    case needsReview

    var displayName: String {
        switch self {
        case .great: return "Great"
        case .keepPracticing: return "Keep Practicing"
        case .needsReview: return "Needs Review"
        }
    }
}

enum StudentReaction: String, Codable {
    case helpful
    case notHelpful
    case none
}

enum VoiceSpeed: String, Codable, CaseIterable {
    case slow
    case normal
    case fast

    var displayName: String { rawValue.capitalized }

    var rate: Float {
        switch self {
        case .slow: return 0.4
        case .normal: return 0.5
        case .fast: return 0.6
        }
    }
}

enum LessonStepType: String, Codable {
    case conceptExplanation
    case workedExample
    case practiceProblem
    case reviewChallenge

    var displayName: String {
        switch self {
        case .conceptExplanation: return "Concept Explanation"
        case .workedExample: return "Worked Example"
        case .practiceProblem: return "Practice Problem"
        case .reviewChallenge: return "Review Challenge"
        }
    }
}

enum StepGradeResult: String, Codable {
    case pass
    case partialPass
    case needsRetry

    var displayName: String {
        switch self {
        case .pass: return "Pass"
        case .partialPass: return "Partial Pass"
        case .needsRetry: return "Needs Retry"
        }
    }
}

enum AccountType: String, Codable, CaseIterable {
    case student
    case parent
    case teacher

    var displayName: String {
        switch self {
        case .student: return "I'm a student"
        case .parent: return "I'm a parent"
        case .teacher: return "I'm a teacher"
        }
    }

    var descriptor: String {
        switch self {
        case .student: return "I'll be using Spark to help with my schoolwork"
        case .parent: return "I'm setting this up for my child"
        case .teacher: return "I'm setting this up for my students"
        }
    }

    var icon: String {
        switch self {
        case .student: return "graduationcap.fill"
        case .parent: return "figure.and.child.holdinghands"
        case .teacher: return "person.crop.rectangle.stack.fill"
        }
    }
}

enum AppearanceMode: String, Codable, CaseIterable {
    case light, dark, system

    var displayName: String { rawValue.capitalized }
}
