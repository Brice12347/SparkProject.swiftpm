import SwiftUI
import SwiftData
import PencilKit
import Combine

@MainActor
class TutorSessionManager: ObservableObject {
    @Published var adviceLog: [AdviceEntry] = []
    @Published var isAISpeaking: Bool = false
    @Published var currentSpeech: String = ""
    @Published var pendingAnnotations: [AIAnnotation] = []
    @Published var aiDrawing = PKDrawing()
    @Published var isAnalyzing = false
    @Published var aiAnnotations: [AIAnnotation] = []

    private(set) var currentSession: HomeworkSession?
    private var student: Student?
    private var modelContext: ModelContext?
    private var debounceTask: Task<Void, Never>?
    private var periodicTimer: Timer?
    private var assignmentContext: String = ""
    private var latestDrawing: PKDrawing = PKDrawing()
    private var accumulatedStrokes: [PKStroke] = []

    private let ocrEngine = VisionOCREngine.shared
    private let speechService = SpeechService.shared
    private var cancellables = Set<AnyCancellable>()

    init() {
        speechService.$isSpeaking
            .receive(on: RunLoop.main)
            .sink { [weak self] speaking in
                self?.isAISpeaking = speaking
            }
            .store(in: &cancellables)
    }

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
        do {
            try modelContext.save()
        } catch {
            print("[Spark] Failed to save session on start: \(error)")
        }
        self.currentSession = session

        if let key = student.claudeAPIKey, !key.isEmpty {
            Task {
                await ClaudeAPIClient.shared.setAPIKey(key)
            }
        }

        // OCR the printed assignment image for textual context (VisionOCR is only used here)
        if let image = assignmentImage {
            Task {
                let text = await ocrEngine.recognize(image: image)
                if !text.isEmpty {
                    assignmentContext += "\n\nAssignment content (OCR):\n\(text)"
                }
            }
        }

        periodicTimer = Timer.scheduledTimer(withTimeInterval: 45, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                guard !self.isAnalyzing, !self.latestDrawing.strokes.isEmpty else { return }
                await self.analyzeCanvas(drawing: self.latestDrawing)
            }
        }
    }

    func onCanvasChanged(drawing: PKDrawing) {
        latestDrawing = drawing
        debounceTask?.cancel()
        debounceTask = Task {
            try? await Task.sleep(nanoseconds: 3_500_000_000)
            guard !Task.isCancelled else { return }
            await analyzeCanvas(drawing: self.latestDrawing)
        }
    }

    func onHelpMeRequested() async {
        debounceTask?.cancel()
        guard !latestDrawing.strokes.isEmpty || !assignmentContext.isEmpty else {
            currentSpeech = "Start writing something and I'll help you right away!"
            speechService.speak(currentSpeech)
            return
        }
        await analyzeCanvas(drawing: latestDrawing)
    }

    func endSession() async {
        debounceTask?.cancel()
        periodicTimer?.invalidate()
        periodicTimer = nil
        speechService.stop()
        accumulatedStrokes = []
        aiAnnotations = []

        guard let session = currentSession else { return }
        session.endedAt = Date()
        session.durationSeconds = Int(Date().timeIntervalSince(session.startedAt))
        session.adviceEntryCount = adviceLog.count

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

        if !adviceLog.isEmpty {
            do {
                let summaries = adviceLog.map { AdviceSummary(topic: $0.topic, summary: $0.summary, fullAdvice: $0.fullAdvice) }
                let analysis = try await ClaudeAPIClient.shared.analyzeSessionConcepts(adviceLog: summaries)
                session.conceptsStrengths = analysis.strengths.map(\.label)
                session.conceptsStruggles = analysis.struggles.map(\.label)
                session.conceptsIdentified = session.conceptsStrengths + session.conceptsStruggles

                if let student = student, let ctx = modelContext {
                    await updateConceptProfiles(analysis: analysis, student: student, context: ctx)
                }
            } catch {
                session.conceptsIdentified = adviceLog.compactMap(\.conceptKey)
            }
        }

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

        do {
            try modelContext?.save()
        } catch {
            print("[Spark] Failed to save session on end: \(error)")
        }
    }

    func setReaction(for advice: AdviceEntry, reaction: StudentReaction) {
        if let index = adviceLog.firstIndex(where: { $0.id == advice.id }) {
            adviceLog[index].studentReaction = reaction
        }
    }

    // MARK: - Private — Canvas Analysis (R1 streaming, R4 guard, R5 allow empty)

    private func analyzeCanvas(drawing: PKDrawing) async {
        // R4: Prevent concurrent calls from debounce + periodicTimer
        guard !isAnalyzing else { return }
        guard let student = student else { return }

        isAnalyzing = true

        let fullCanvasSize = CGSize(width: 2000, height: 4000)

        // R1: Render the canvas to a JPEG image for Claude vision (replaces OCR)
        let captureRect: CGRect
        if drawing.bounds.isEmpty {
            captureRect = CGRect(origin: .zero, size: fullCanvasSize)
        } else {
            captureRect = drawing.bounds.insetBy(dx: -40, dy: -40)
        }
        let image = drawing.image(from: captureRect, scale: 2.0)
        guard let jpegData = image.jpegData(compressionQuality: 0.7) else {
            isAnalyzing = false
            return
        }
        let base64 = jpegData.base64EncodedString()

        // R5: No "skip if text is empty" guard — always send to Claude.
        // Claude can see a blank canvas and offer an opening prompt.

        do {
            let prevSummaries = adviceLog.prefix(5).map {
                AdviceSummary(topic: $0.topic, summary: $0.summary, fullAdvice: $0.fullAdvice)
            }
            let stream = try await ClaudeAPIClient.shared.analyzeHomework(
                studentImageBase64: base64,
                assignmentContext: assignmentContext,
                gradeLevel: student.gradeLevel,
                learningStyleTags: student.learningStyleTags,
                previousAdvice: prevSummaries
            )

            // Consume the stream, extracting speech sentences incrementally
            var buffer = ""
            var speechProcessedLength = 0

            for await delta in stream {
                buffer += delta
                let sentences = extractSpeechSentences(from: buffer, processedLength: &speechProcessedLength)
                for sentence in sentences {
                    currentSpeech = sentence
                    speechService.enqueueSentence(sentence)
                }
            }

            // Parse the complete JSON for annotations + advice_entry
            let jsonText = extractJSON(from: buffer)
            guard let jsonData = jsonText.data(using: .utf8) else {
                throw ClaudeError.invalidResponse
            }
            let response = try JSONDecoder().decode(AIAnnotationPayload.self, from: jsonData)

            // If no sentences were extracted during streaming, speak the full speech field
            if speechProcessedLength == 0, !response.speech.isEmpty {
                currentSpeech = response.speech
                speechService.speak(response.speech)
            }

            pendingAnnotations = response.annotations
            renderAnnotationsToDrawing(response.annotations, canvasSize: fullCanvasSize)

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
            speechService.speak(currentSpeech)
        }

        isAnalyzing = false
    }

    // MARK: - Incremental Speech Extraction

    /// Scans the streaming buffer for completed sentences within the "speech" JSON field.
    /// Uses processedLength to track how much of the speech content has already been extracted.
    private func extractSpeechSentences(from buffer: String, processedLength: inout Int) -> [String] {
        guard let keyRange = buffer.range(of: "\"speech\"") else { return [] }

        let afterKey = buffer[keyRange.upperBound...]
        guard let colonIdx = afterKey.firstIndex(of: ":") else { return [] }
        let afterColon = buffer[buffer.index(after: colonIdx)...]
        guard let openQuote = afterColon.firstIndex(of: "\"") else { return [] }
        let contentStart = buffer.index(after: openQuote)

        // Walk the string content handling escape sequences
        var content = ""
        var i = contentStart
        while i < buffer.endIndex {
            let ch = buffer[i]
            if ch == "\\" {
                let next = buffer.index(after: i)
                if next < buffer.endIndex {
                    let escaped = buffer[next]
                    switch escaped {
                    case "n": content.append("\n")
                    case "t": content.append("\t")
                    case "\"": content.append("\"")
                    case "\\": content.append("\\")
                    default: content.append(escaped)
                    }
                    i = buffer.index(after: next)
                    continue
                }
            }
            if ch == "\"" { break }
            content.append(ch)
            i = buffer.index(after: i)
        }

        guard content.count > processedLength else { return [] }
        let unprocessed = String(content.dropFirst(processedLength))

        var sentences: [String] = []
        var current = ""

        for char in unprocessed {
            current.append(char)
            if char == "." || char == "!" || char == "?" {
                let trimmed = current.trimmingCharacters(in: .whitespaces)
                if !trimmed.isEmpty {
                    sentences.append(trimmed)
                }
                processedLength += current.count
                current = ""
            }
        }

        return sentences
    }

    // MARK: - Annotation Rendering (R2 write→UILabel, R3 accumulation)

    private func renderAnnotationsToDrawing(_ annotations: [AIAnnotation], canvasSize: CGSize) {
        var newStrokes: [PKStroke] = []

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
                        newStrokes.append(stroke)
                    }
                }

            case .arrow:
                if let from = annotation.from, let to = annotation.to {
                    let start = CGPoint(x: from.x * canvasSize.width, y: from.y * canvasSize.height)
                    let end = CGPoint(x: to.x * canvasSize.width, y: to.y * canvasSize.height)
                    let points = arrowPoints(from: start, to: end)
                    if let stroke = createStroke(from: points, ink: ink) {
                        newStrokes.append(stroke)
                    }
                }

            case .write:
                // R2: "write" annotations are rendered as UILabels in CanvasView,
                // not as PKStrokes. No stroke creation here.
                break
            }
        }

        // R3: Accumulate strokes across analyses; cap at 200
        accumulatedStrokes.append(contentsOf: newStrokes)
        if accumulatedStrokes.count > 200 {
            accumulatedStrokes.removeFirst(accumulatedStrokes.count - 200)
        }

        var drawing = PKDrawing()
        drawing.strokes = accumulatedStrokes
        self.aiDrawing = drawing

        // R2: Publish the full annotation list for UILabel rendering in CanvasView
        self.aiAnnotations = annotations
    }

    // MARK: - Geometry Helpers

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
        let controlPoints = points.enumerated().map { index, pt in
            PKStrokePoint(
                location: pt,
                timeOffset: Double(index) * 0.01,
                size: CGSize(width: width, height: width),
                opacity: 0.9,
                force: 1.0,
                azimuth: 0,
                altitude: .pi / 2
            )
        }
        let path = PKStrokePath(controlPoints: controlPoints, creationDate: Date())
        return PKStroke(ink: ink, path: path)
    }

    // MARK: - JSON Extraction

    private func extractJSON(from text: String) -> String {
        if let firstBrace = text.firstIndex(of: "{"),
           let lastBrace = text.lastIndex(of: "}") {
            return String(text[firstBrace...lastBrace])
        }
        if let firstBracket = text.firstIndex(of: "["),
           let lastBracket = text.lastIndex(of: "]") {
            return String(text[firstBracket...lastBracket])
        }
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Concept Profile Updates

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

        do {
            try context.save()
        } catch {
            print("[Spark] Failed to save concept profiles: \(error)")
        }
    }

    private func findConceptProfile(in context: ModelContext, studentId: UUID, conceptKey: String) -> ConceptProfile? {
        let descriptor = FetchDescriptor<ConceptProfile>(
            predicate: #Predicate { $0.studentId == studentId && $0.conceptKey == conceptKey }
        )
        return try? context.fetch(descriptor).first
    }
}
