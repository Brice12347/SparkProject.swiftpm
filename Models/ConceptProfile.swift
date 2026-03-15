import Foundation
import SwiftData

@Model
final class ConceptProfile {
    var id: UUID
    var studentId: UUID
    var conceptKey: String
    var subjectRaw: String
    var label: String
    var proficiencyLevel: Int
    var firstSeenAt: Date
    var lastUpdatedAt: Date
    var sessionAppearanceCount: Int
    var lessonPlanId: UUID?

    init(
        studentId: UUID,
        conceptKey: String,
        subject: Subject,
        label: String
    ) {
        self.id = UUID()
        self.studentId = studentId
        self.conceptKey = conceptKey
        self.subjectRaw = subject.rawValue
        self.label = label
        self.proficiencyLevel = 1
        self.firstSeenAt = Date()
        self.lastUpdatedAt = Date()
        self.sessionAppearanceCount = 1
    }

    var subject: Subject {
        get { Subject(rawValue: subjectRaw) ?? .other }
        set { subjectRaw = newValue.rawValue }
    }

    var isStrength: Bool { proficiencyLevel >= 4 }
    var isStruggling: Bool { proficiencyLevel == 2 }
    var isPracticing: Bool { proficiencyLevel == 3 }
    var isDeveloping: Bool { proficiencyLevel == 4 }
    var isConfident: Bool { proficiencyLevel == 5 }
}
