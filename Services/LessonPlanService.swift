import Foundation
import SwiftData

@MainActor
class LessonPlanService: ObservableObject {

    private var modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func checkAndGenerateIfNeeded(student: Student) async {
        let studentId = student.id
        let descriptor = FetchDescriptor<ConceptProfile>(
            predicate: #Predicate { $0.studentId == studentId && $0.proficiencyLevel == 2 }
        )
        let struggles = (try? modelContext.fetch(descriptor)) ?? []

        for concept in struggles where concept.lessonPlanId == nil {
            await generateLessonPlan(for: concept, student: student)
        }
    }

    func generateLessonPlan(for concept: ConceptProfile, student: Student) async {
        do {
            let steps = try await ClaudeAPIClient.shared.generateLessonPlan(
                conceptKey: concept.conceptKey,
                conceptLabel: concept.label,
                subject: concept.subjectRaw,
                gradeLevel: student.gradeLevel,
                learningStyleTags: student.learningStyleTags
            )

            let plan = LessonPlan(
                studentId: student.id,
                conceptKey: concept.conceptKey,
                conceptLabel: concept.label,
                subject: concept.subject,
                steps: steps
            )

            modelContext.insert(plan)
            concept.lessonPlanId = plan.id
            try? modelContext.save()
        } catch {
            // Lesson plan generation failed silently
        }
    }

    func getLessonPlans(studentId: UUID) -> [LessonPlan] {
        let descriptor = FetchDescriptor<LessonPlan>(
            predicate: #Predicate { $0.studentId == studentId },
            sortBy: [SortDescriptor(\LessonPlan.generatedAt, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func markStepComplete(plan: LessonPlan, stepIndex: Int, result: StepGradeResult) {
        var steps = plan.steps
        guard stepIndex < steps.count else { return }
        steps[stepIndex].isCompleted = true
        steps[stepIndex].gradeResult = result
        plan.steps = steps

        if result == .pass || result == .partialPass {
            plan.currentStepIndex = min(stepIndex + 1, steps.count)
        }

        if plan.currentStepIndex >= steps.count {
            plan.isComplete = true
            plan.completedAt = Date()
        }

        try? modelContext.save()
    }
}
