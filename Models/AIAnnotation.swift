import Foundation

struct AIAnnotationPayload: Codable {
    var speech: String
    var annotations: [AIAnnotation]
    var adviceEntry: AIAdviceEntryPayload
    
    enum CodingKeys: String, CodingKey {
        case speech
        case annotations
        case adviceEntry = "advice_entry"
    }
}

struct AIAnnotation: Codable, Identifiable {
    var id: UUID = UUID()
    var type: AnnotationType
    var targetRegion: AnnotationRegion?
    var from: AnnotationPoint?
    var to: AnnotationPoint?
    var text: String?
    var position: AnnotationPoint?
    var color: String
    var label: String?
    var style: String?

    enum CodingKeys: String, CodingKey {
        case type, color, label, style, text, position, from, to
        case targetRegion = "target_region"
    }

    enum AnnotationType: String, Codable {
        case circle
        case arrow
        case write
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        self.type = try container.decode(AnnotationType.self, forKey: .type)
        self.targetRegion = try container.decodeIfPresent(AnnotationRegion.self, forKey: .targetRegion)
        self.from = try container.decodeIfPresent(AnnotationPoint.self, forKey: .from)
        self.to = try container.decodeIfPresent(AnnotationPoint.self, forKey: .to)
        self.text = try container.decodeIfPresent(String.self, forKey: .text)
        self.position = try container.decodeIfPresent(AnnotationPoint.self, forKey: .position)
        self.color = try container.decode(String.self, forKey: .color)
        self.label = try container.decodeIfPresent(String.self, forKey: .label)
        self.style = try container.decodeIfPresent(String.self, forKey: .style)
    }

    init(type: AnnotationType, color: String, targetRegion: AnnotationRegion? = nil,
         from: AnnotationPoint? = nil, to: AnnotationPoint? = nil,
         text: String? = nil, position: AnnotationPoint? = nil,
         label: String? = nil, style: String? = nil) {
        self.id = UUID()
        self.type = type
        self.targetRegion = targetRegion
        self.from = from
        self.to = to
        self.text = text
        self.position = position
        self.color = color
        self.label = label
        self.style = style
    }
}

struct AnnotationRegion: Codable {
    var x: Double
    var y: Double
    var radius: Double
}

struct AnnotationPoint: Codable {
    var x: Double
    var y: Double
}

struct AIAdviceEntryPayload: Codable {
    var topic: String
    var summary: String
    var fullAdvice: String
    var conceptKey: String?

    enum CodingKeys: String, CodingKey {
        case topic, summary
        case fullAdvice = "full_advice"
        case conceptKey = "concept_key"
    }
}

struct ConceptAnalysisResult: Codable {
    var strengths: [ConceptItem]
    var struggles: [ConceptItem]
}

struct ConceptItem: Codable {
    var conceptKey: String
    var label: String
    var subject: String

    enum CodingKeys: String, CodingKey {
        case conceptKey = "concept_key"
        case label, subject
    }
}
