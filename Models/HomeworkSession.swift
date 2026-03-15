import Foundation
import SwiftData

@Model
final class HomeworkSession {
    var id: UUID
    var studentId: UUID
    var assignmentName: String?
    var subjectRaw: String
    var assignmentImageData: Data?
    var startedAt: Date
    var endedAt: Date?
    var durationSeconds: Int
    var adviceEntryCount: Int
    var performanceTagRaw: String?
    var conceptsIdentified: [String]
    var conceptsStrengths: [String]
    var conceptsStruggles: [String]

    init(
        studentId: UUID,
        subject: Subject,
        assignmentName: String? = nil,
        assignmentImageData: Data? = nil
    ) {
        self.id = UUID()
        self.studentId = studentId
        self.assignmentName = assignmentName
        self.subjectRaw = subject.rawValue
        self.assignmentImageData = assignmentImageData
        self.startedAt = Date()
        self.durationSeconds = 0
        self.adviceEntryCount = 0
        self.conceptsIdentified = []
        self.conceptsStrengths = []
        self.conceptsStruggles = []
    }

    var subject: Subject {
        get { Subject(rawValue: subjectRaw) ?? .other }
        set { subjectRaw = newValue.rawValue }
    }

    var performanceTag: PerformanceTag? {
        get {
            guard let raw = performanceTagRaw else { return nil }
            return PerformanceTag(rawValue: raw)
        }
        set { performanceTagRaw = newValue?.rawValue }
    }

    var displayName: String {
        assignmentName ?? "\(subject.displayName) Session"
    }

    var formattedDate: String {
        startedAt.formatted(date: .abbreviated, time: .omitted)
    }

    var formattedDuration: String {
        let minutes = durationSeconds / 60
        if minutes < 1 { return "< 1 min" }
        return "\(minutes) min"
    }
}
