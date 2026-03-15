import Foundation
import SwiftData

@MainActor
class StudentProfileService: ObservableObject {

    private var modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Concept Profile CRUD

    func getConceptsAtLevel(_ level: Int, studentId: UUID) -> [ConceptProfile] {
        let descriptor = FetchDescriptor<ConceptProfile>(
            predicate: #Predicate { $0.studentId == studentId && $0.proficiencyLevel == level }
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func getStrengths(studentId: UUID) -> [ConceptProfile] {
        let descriptor = FetchDescriptor<ConceptProfile>(
            predicate: #Predicate { $0.studentId == studentId && $0.proficiencyLevel >= 4 }
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func getStruggles(studentId: UUID) -> [ConceptProfile] {
        let descriptor = FetchDescriptor<ConceptProfile>(
            predicate: #Predicate { $0.studentId == studentId && $0.proficiencyLevel == 2 }
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func getGrowingConcepts(studentId: UUID) -> [ConceptProfile] {
        let descriptor = FetchDescriptor<ConceptProfile>(
            predicate: #Predicate { $0.studentId == studentId && $0.proficiencyLevel == 3 }
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func getAllConcepts(studentId: UUID) -> [ConceptProfile] {
        let descriptor = FetchDescriptor<ConceptProfile>(
            predicate: #Predicate { $0.studentId == studentId }
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    // MARK: - Proficiency Level Transitions

    func recordConceptAppearance(studentId: UUID, conceptKey: String, subject: Subject, label: String) {
        let descriptor = FetchDescriptor<ConceptProfile>(
            predicate: #Predicate { $0.studentId == studentId && $0.conceptKey == conceptKey }
        )

        if let existing = try? modelContext.fetch(descriptor).first {
            existing.sessionAppearanceCount += 1
            existing.lastUpdatedAt = Date()

            // 1 -> 2: Appeared in 2+ sessions as a struggle
            if existing.proficiencyLevel == 1 && existing.sessionAppearanceCount >= 2 {
                existing.proficiencyLevel = 2
            }
        } else {
            // 0 -> 1: First appearance
            let profile = ConceptProfile(
                studentId: studentId,
                conceptKey: conceptKey,
                subject: subject,
                label: label
            )
            modelContext.insert(profile)
        }

        try? modelContext.save()
    }

    func advanceToPracticing(studentId: UUID, conceptKey: String) {
        guard let profile = findConcept(studentId: studentId, conceptKey: conceptKey) else { return }
        // 2 -> 3: Lesson plan started
        if profile.proficiencyLevel == 2 {
            profile.proficiencyLevel = 3
            profile.lastUpdatedAt = Date()
            try? modelContext.save()
        }
    }

    func advanceToDeveloping(studentId: UUID, conceptKey: String) {
        guard let profile = findConcept(studentId: studentId, conceptKey: conceptKey) else { return }
        // 3 -> 4: Passed 2+ lesson steps
        if profile.proficiencyLevel == 3 {
            profile.proficiencyLevel = 4
            profile.lastUpdatedAt = Date()
            try? modelContext.save()
        }
    }

    func advanceToConfident(studentId: UUID, conceptKey: String) {
        guard let profile = findConcept(studentId: studentId, conceptKey: conceptKey) else { return }
        // 4 -> 5: No struggles across 3+ sessions
        if profile.proficiencyLevel == 4 {
            profile.proficiencyLevel = 5
            profile.lastUpdatedAt = Date()
            try? modelContext.save()
        }
    }

    func linkLessonPlan(_ planId: UUID, to conceptKey: String, studentId: UUID) {
        guard let profile = findConcept(studentId: studentId, conceptKey: conceptKey) else { return }
        profile.lessonPlanId = planId
        try? modelContext.save()
    }

    // MARK: - Skills Summary (for radar chart)

    func skillsRadarData(studentId: UUID) -> [SubjectSkillLevel] {
        let concepts = getAllConcepts(studentId: studentId)
        var subjectLevels: [Subject: [Int]] = [:]

        for concept in concepts {
            subjectLevels[concept.subject, default: []].append(concept.proficiencyLevel)
        }

        return Subject.allCases.compactMap { subject in
            let levels = subjectLevels[subject] ?? []
            let avg = levels.isEmpty ? 0.0 : Double(levels.reduce(0, +)) / Double(levels.count)
            return SubjectSkillLevel(subject: subject, level: avg / 5.0) // Normalize 0-1
        }
    }

    private func findConcept(studentId: UUID, conceptKey: String) -> ConceptProfile? {
        let descriptor = FetchDescriptor<ConceptProfile>(
            predicate: #Predicate { $0.studentId == studentId && $0.conceptKey == conceptKey }
        )
        return try? modelContext.fetch(descriptor).first
    }
}

struct SubjectSkillLevel: Identifiable {
    let subject: Subject
    let level: Double // 0.0 - 1.0
    var id: String { subject.rawValue }
}
