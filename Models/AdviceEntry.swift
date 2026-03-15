import Foundation
import SwiftData

@Model
final class AdviceEntry {
    var id: UUID
    var sessionId: UUID
    var studentId: UUID
    var timestamp: Date
    var topic: String
    var summary: String
    var fullAdvice: String
    var annotationPayloadData: Data?
    var canvasSnapshotData: Data?
    var studentReactionRaw: String
    var conceptKey: String?

    init(
        sessionId: UUID,
        studentId: UUID,
        topic: String,
        summary: String,
        fullAdvice: String,
        conceptKey: String? = nil
    ) {
        self.id = UUID()
        self.sessionId = sessionId
        self.studentId = studentId
        self.timestamp = Date()
        self.topic = topic
        self.summary = summary
        self.fullAdvice = fullAdvice
        self.studentReactionRaw = StudentReaction.none.rawValue
        self.conceptKey = conceptKey
    }

    var studentReaction: StudentReaction {
        get { StudentReaction(rawValue: studentReactionRaw) ?? .none }
        set { studentReactionRaw = newValue.rawValue }
    }

    var formattedTime: String {
        timestamp.formatted(date: .omitted, time: .shortened)
    }
}
