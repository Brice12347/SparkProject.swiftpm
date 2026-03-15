import Foundation
import SwiftData

@Model
final class LessonPlan {
    var id: UUID
    var studentId: UUID
    var conceptKey: String
    var conceptLabel: String
    var subjectRaw: String
    var generatedAt: Date
    var stepsData: Data?
    var isComplete: Bool
    var currentStepIndex: Int
    var completedAt: Date?

    init(
        studentId: UUID,
        conceptKey: String,
        conceptLabel: String,
        subject: Subject,
        steps: [LessonStep] = []
    ) {
        self.id = UUID()
        self.studentId = studentId
        self.conceptKey = conceptKey
        self.conceptLabel = conceptLabel
        self.subjectRaw = subject.rawValue
        self.generatedAt = Date()
        self.isComplete = false
        self.currentStepIndex = 0
        self.steps = steps
    }

    var subject: Subject {
        get { Subject(rawValue: subjectRaw) ?? .other }
        set { subjectRaw = newValue.rawValue }
    }

    var steps: [LessonStep] {
        get {
            guard let data = stepsData else { return [] }
            return (try? JSONDecoder().decode([LessonStep].self, from: data)) ?? []
        }
        set {
            stepsData = try? JSONEncoder().encode(newValue)
        }
    }

    var totalSteps: Int { steps.count }

    var progress: Double {
        guard totalSteps > 0 else { return 0 }
        return Double(currentStepIndex) / Double(totalSteps)
    }

    var currentStep: LessonStep? {
        let allSteps = steps
        guard currentStepIndex < allSteps.count else { return nil }
        return allSteps[currentStepIndex]
    }
}

struct LessonStep: Codable, Identifiable {
    var id: UUID
    var index: Int
    var title: String
    var typeRaw: String
    var explanationText: String
    var problemText: String?
    var workedExampleAnnotationsData: Data?
    var hintText: String?
    var isCompleted: Bool
    var gradeResultRaw: String?

    init(
        index: Int,
        title: String,
        type: LessonStepType,
        explanationText: String,
        problemText: String? = nil,
        hintText: String? = nil
    ) {
        self.id = UUID()
        self.index = index
        self.title = title
        self.typeRaw = type.rawValue
        self.explanationText = explanationText
        self.problemText = problemText
        self.hintText = hintText
        self.isCompleted = false
    }

    var type: LessonStepType {
        get { LessonStepType(rawValue: typeRaw) ?? .conceptExplanation }
        set { typeRaw = newValue.rawValue }
    }

    var gradeResult: StepGradeResult? {
        get {
            guard let raw = gradeResultRaw else { return nil }
            return StepGradeResult(rawValue: raw)
        }
        set { gradeResultRaw = newValue?.rawValue }
    }
}
