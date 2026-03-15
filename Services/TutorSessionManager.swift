import SwiftUI
import SwiftData
import PencilKit

@MainActor
class TutorSessionManager: ObservableObject {
    @Published var adviceLog: [AdviceEntry] = []
    @Published var isAISpeaking: Bool = false
    @Published var currentSpeech: String = ""
    @Published var pendingAnnotations: [AIAnnotation] = []
    @Published var aiDrawing = PKDrawing()
    @Published var isAnalyzing = false

    private(set) var currentSession: HomeworkSession?
    private var student: Student?
    private var modelContext: ModelContext?
    private var debounceTask: Task<Void, Never>?
    private var assignmentContext: String = ""

    private let ocrEngine = VisionOCREngine.shared
    private let speechService = SpeechService.shared

    func startSession(
        student: Student,
        subject: Subject,
        assignmentName: String?,
        assignmentImage: UIImage?,
        modelContext: ModelContext
    ) {
        self.student = student
        self.modelContext = modelContext
        self.assignmentContext = "\(subject.displayName) assignment" +
            (assignmentName.map { ": \($0)" } ?? "")

        let session = HomeworkSession(
            studentId: student.id,
            subject: subject,
            assignmentName: assignmentName,
            assignmentImageData: assignmentImage?.jpegData(compressionQuality: 0.7)
        )

        modelContext.insert(session)
        self.currentSession = session

        // Set API key from student settings
        if let key = student.claudeAPIKey, !key.isEmpty {
            Task {
                await ClaudeAPIClient.shared.setAPIKey(key)
            }
        }

        // If there's an assignment image, OCR it for initial context
        if let image = assignmentImage {
            Task {
                let text = await ocrEngine.recognize(image: image)
                if !text.isEmpty {
                    assignmentContext += "\n\nAssignment content (OCR):\n\(text)"
                }
            }
        }
    }

    func onCanvasChanged(drawing: PKDrawing) {
        debounceTask?.cancel()
        debounceTask = Task {
            try? await Task.sleep(nanoseconds: 3_500_000_000)
            guard !Task.isCancelled else { return }
            await analyzeCanvas(drawing: drawing)
        }
    }

    func onHelpMeRequested() async {
        debounceTask?.cancel()
        guard let session = currentSession else { return }
        // Synthesize a quick "analyzing" message
        isAnalyzing = true
        currentSpeech = "Let me take a closer look..."
        speechService.speak("Let me take a closer look at your work.")
        // Would analyze real canvas here
        isAnalyzing = false
    }

    func endSession() async {
        debounceTask?.cancel()
        speechService.stop()

        guard let session = currentSession else { return }
        session.endedAt = Date()
        session.durationSeconds = Int(Date().timeIntervalSince(session.startedAt))
        session.adviceEntryCount = adviceLog.count

        // Determine performance tag
        if adviceLog.isEmpty {
            session.performanceTag = .great
        } else {
            let struggles = adviceLog.filter { $0.conceptKey != nil }.count
            if struggles > adviceLog.count / 2 {
                session.performanceTag = .needsReview
            } else if struggles > 0 {
                session.performanceTag = .keepPracticing
            } else {
                session.performanceTag = .great
            }
        }

        // Analyze concepts if we have advice
        if !adviceLog.isEmpty {
            do {
                let summaries = adviceLog.map { AdviceSummary(topic: $0.topic, summary: $0.summary, fullAdvice: $0.fullAdvice) }
                let analysis = try await ClaudeAPIClient.shared.analyzeSessionConcepts(adviceLog: summaries)
                session.conceptsStrengths = analysis.strengths.map(\.label)
                session.conceptsStruggles = analysis.struggles.map(\.label)
                session.conceptsIdentified = session.conceptsStrengths + session.conceptsStruggles

                // Update concept profiles
                if let student = student, let ctx = modelContext {
                    await updateConceptProfiles(analysis: analysis, student: student, context: ctx)
                }
            } catch {
                session.conceptsIdentified = adviceLog.compactMap(\.conceptKey)
            }
        }

        // Update student streak
        if let student = student {
            if !student.todayHasSession {
                if let lastDate = student.lastSessionDate,
                   Calendar.current.isDateInYesterday(lastDate) {
                    student.streakCount += 1
                } else if student.lastSessionDate == nil {
                    student.streakCount = 1
                }
            }
            student.lastSessionDate = Date()
        }

        try? modelContext?.save()
    }

    func setReaction(for advice: AdviceEntry, reaction: StudentReaction) {
        if let index = adviceLog.firstIndex(where: { $0.id == advice.id }) {
            adviceLog[index].studentReaction = reaction
        }
    }

    // MARK: - Private

    private func analyzeCanvas(drawing: PKDrawing) async {
        guard let student = student else { return }

        isAnalyzing = true

        // Generate image from drawing for OCR
        let bounds = CGRect(x: 0, y: 0, width: 1024, height: 1024)
        let image = drawing.image(from: bounds, scale: 1.0)
        let extractedText = await ocrEngine.recognize(image: image)

        guard !extractedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            isAnalyzing = false
            return
        }

        do {
            let prevSummaries = adviceLog.prefix(5).map { AdviceSummary(topic: $0.topic, summary: $0.summary, fullAdvice: $0.fullAdvice) }
            let response = try await ClaudeAPIClient.shared.analyzeHomework(
                studentText: extractedText,
                assignmentContext: assignmentContext,
                gradeLevel: student.gradeLevel,
                learningStyleTags: student.learningStyleTags,
                previousAdvice: prevSummaries
            )

            // Render annotations
            pendingAnnotations = response.annotations
            await renderAnnotationsToDrawing(response.annotations, canvasSize: bounds.size)

            // Speak feedback
            currentSpeech = response.speech
            isAISpeaking = true
            speechService.speak(response.speech)

            // Log advice entry
            let entry = AdviceEntry(
                sessionId: currentSession?.id ?? UUID(),
                studentId: student.id,
                topic: response.adviceEntry.topic,
                summary: response.adviceEntry.summary,
                fullAdvice: response.adviceEntry.fullAdvice,
                conceptKey: response.adviceEntry.conceptKey
            )
            adviceLog.insert(entry, at: 0)
            modelContext?.insert(entry)

            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()

        } catch {
            currentSpeech = "I had trouble analyzing your work. Keep going and I'll try again!"
        }

        isAnalyzing = false
    }

    private func renderAnnotationsToDrawing(_ annotations: [AIAnnotation], canvasSize: CGSize) async {
        var strokes: [PKStroke] = []

        for annotation in annotations {
            let color = UIColor(Color(hex: annotation.color))
            let ink = PKInk(.pen, color: color)

            switch annotation.type {
            case .circle:
                if let region = annotation.targetRegion {
                    let center = CGPoint(
                        x: region.x * canvasSize.width,
                        y: region.y * canvasSize.height
                    )
                    let radius = region.radius * canvasSize.width
                    let points = circlePoints(center: center, radius: radius)
                    if let stroke = createStroke(from: points, ink: ink) {
                        strokes.append(stroke)
                    }
                }

            case .arrow:
                if let from = annotation.from, let to = annotation.to {
                    let start = CGPoint(x: from.x * canvasSize.width, y: from.y * canvasSize.height)
                    let end = CGPoint(x: to.x * canvasSize.width, y: to.y * canvasSize.height)
                    let points = arrowPoints(from: start, to: end)
                    if let stroke = createStroke(from: points, ink: ink) {
                        strokes.append(stroke)
                    }
                }

            case .write:
                // Text annotations rendered as a small dot at position for now
                if let pos = annotation.position {
                    let point = CGPoint(x: pos.x * canvasSize.width, y: pos.y * canvasSize.height)
                    let points = [point, CGPoint(x: point.x + 2, y: point.y)]
                    if let stroke = createStroke(from: points, ink: ink, width: 3) {
                        strokes.append(stroke)
                    }
                }
            }
        }

        var drawing = PKDrawing()
        drawing.strokes = strokes
        self.aiDrawing = drawing
    }

    private func circlePoints(center: CGPoint, radius: CGFloat, segments: Int = 36) -> [CGPoint] {
        (0...segments).map { i in
            let angle = CGFloat(i) / CGFloat(segments) * 2 * .pi
            return CGPoint(
                x: center.x + radius * cos(angle),
                y: center.y + radius * sin(angle)
            )
        }
    }

    private func arrowPoints(from start: CGPoint, to end: CGPoint) -> [CGPoint] {
        let dx = end.x - start.x
        let dy = end.y - start.y
        let angle = atan2(dy, dx)
        let headLength: CGFloat = 12

        let left = CGPoint(
            x: end.x - headLength * cos(angle - .pi / 6),
            y: end.y - headLength * sin(angle - .pi / 6)
        )
        let right = CGPoint(
            x: end.x - headLength * cos(angle + .pi / 6),
            y: end.y - headLength * sin(angle + .pi / 6)
        )

        return [start, end, left, end, right]
    }

    private func createStroke(from points: [CGPoint], ink: PKInk, width: CGFloat = 2) -> PKStroke? {
        guard points.count >= 2 else { return nil }
        let controlPoints = points.map { pt in
            PKStrokePoint(
                location: pt,
                timeOffset: 0,
                size: CGSize(width: width, height: width),
                opacity: 0.85,
                force: 0.5,
                azimuth: 0,
                altitude: .pi / 2
            )
        }
        let path = PKStrokePath(controlPoints: controlPoints, creationDate: Date())
        return PKStroke(ink: ink, path: path)
    }

    private func updateConceptProfiles(
        analysis: ConceptAnalysisResult,
        student: Student,
        context: ModelContext
    ) async {
        let sid = student.id

        for item in analysis.strengths {
            let subject = Subject(rawValue: item.subject) ?? .other
            if let existing = findConceptProfile(in: context, studentId: sid, conceptKey: item.conceptKey) {
                if existing.proficiencyLevel < 4 {
                    existing.proficiencyLevel = 4
                }
                existing.lastUpdatedAt = Date()
                existing.sessionAppearanceCount += 1
            } else {
                let profile = ConceptProfile(studentId: sid, conceptKey: item.conceptKey, subject: subject, label: item.label)
                profile.proficiencyLevel = 4
                context.insert(profile)
            }
        }

        for item in analysis.struggles {
            let subject = Subject(rawValue: item.subject) ?? .other
            if let existing = findConceptProfile(in: context, studentId: sid, conceptKey: item.conceptKey) {
                existing.sessionAppearanceCount += 1
                if existing.sessionAppearanceCount >= 2 && existing.proficiencyLevel < 2 {
                    existing.proficiencyLevel = 2
                }
                existing.lastUpdatedAt = Date()
            } else {
                let profile = ConceptProfile(studentId: sid, conceptKey: item.conceptKey, subject: subject, label: item.label)
                profile.proficiencyLevel = 1
                context.insert(profile)
            }
        }

        try? context.save()
    }
    
    private func findConceptProfile(in context: ModelContext, studentId: UUID, conceptKey: String) -> ConceptProfile? {
            let descriptor = FetchDescriptor<ConceptProfile>(
                predicate: #Predicate { $0.studentId == studentId && $0.conceptKey == conceptKey }
            )
            return try? context.fetch(descriptor).first
    }
}

extension ClaudeAPIClient {
    func setAPIKey(_ key: String) {
        apiKey = key
    }
}
