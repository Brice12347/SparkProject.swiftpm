import Foundation

struct AdviceSummary: Sendable {
    let topic: String
    let summary: String
    let fullAdvice: String
}

actor ClaudeAPIClient {
    static let shared = ClaudeAPIClient()
    
    private let baseURL = "https://api.anthropic.com/v1/messages"
    private let model = "claude-sonnet-4-20250514"
    
    var apiKey: String = "sk-ant-api03--EP3eDfP_LTX_lJuecmqBvQiFwr0awaoT2AEhoFF6cWgzpJOtdmQj0ML1OksJrdrPw507bZkI6c6ZW9xevw2-g-mfbtegA"
    
    // MARK: - Non-streaming request (batch calls)

    private func makeRequest(systemPrompt: String, userMessage: String) async throws -> String {
        guard !apiKey.isEmpty else {
            throw ClaudeError.noAPIKey
        }
        
        var request = URLRequest(url: URL(string: baseURL)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        
        let body: [String: Any] = [
            "model": model,
            "max_tokens": 4096,
            "system": systemPrompt,
            "messages": [
                ["role": "user", "content": userMessage]
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              200..<300 ~= httpResponse.statusCode else {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw ClaudeError.apiError(errorBody)
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let content = json?["content"] as? [[String: Any]],
              let text = content.first?["text"] as? String else {
            throw ClaudeError.invalidResponse
        }
        
        return text
    }

    // MARK: - Non-streaming request with multi-part content (vision)

    private func makeRequestWithContent(systemPrompt: String, userContent: [[String: Any]]) async throws -> String {
        guard !apiKey.isEmpty else {
            throw ClaudeError.noAPIKey
        }

        var request = URLRequest(url: URL(string: baseURL)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

        let body: [String: Any] = [
            "model": model,
            "max_tokens": 4096,
            "system": systemPrompt,
            "messages": [
                ["role": "user", "content": userContent]
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              200..<300 ~= httpResponse.statusCode else {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw ClaudeError.apiError(errorBody)
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let content = json?["content"] as? [[String: Any]],
              let text = content.first?["text"] as? String else {
            throw ClaudeError.invalidResponse
        }

        return text
    }

    // MARK: - Streaming request (SSE → AsyncStream of delta text)

    private func makeStreamingRequest(systemPrompt: String, userContent: [[String: Any]]) async throws -> AsyncStream<String> {
        guard !apiKey.isEmpty else {
            throw ClaudeError.noAPIKey
        }

        var request = URLRequest(url: URL(string: baseURL)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

        let body: [String: Any] = [
            "model": model,
            "max_tokens": 4096,
            "stream": true,
            "system": systemPrompt,
            "messages": [
                ["role": "user", "content": userContent]
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (bytes, response) = try await URLSession.shared.bytes(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              200..<300 ~= httpResponse.statusCode else {
            // For error responses from streaming endpoints, collect available data
            var errorChunks: [UInt8] = []
            for try await byte in bytes { errorChunks.append(byte) }
            let errorBody = String(data: Data(errorChunks), encoding: .utf8) ?? "Unknown streaming error"
            throw ClaudeError.apiError(errorBody)
        }

        return AsyncStream<String> { continuation in
            let task = Task {
                do {
                    for try await line in bytes.lines {
                        guard !Task.isCancelled else { break }

                        guard line.hasPrefix("data: ") else { continue }
                        let payload = String(line.dropFirst(6))

                        if payload == "[DONE]" { break }

                        guard let data = payload.data(using: .utf8),
                              let event = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                              let type = event["type"] as? String else {
                            continue
                        }

                        if type == "content_block_delta",
                           let delta = event["delta"] as? [String: Any],
                           let deltaType = delta["type"] as? String,
                           deltaType == "text_delta",
                           let text = delta["text"] as? String {
                            continuation.yield(text)
                        }
                    }
                } catch {
                    // Stream interrupted — finish gracefully
                }
                continuation.finish()
            }

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }
    
    // MARK: - Homework Analysis (streaming, vision input)
    
    func analyzeHomework(
        studentImageBase64: String,
        assignmentContext: String,
        gradeLevel: String,
        learningStyleTags: [String],
        previousAdvice: [AdviceSummary]
    ) async throws -> AsyncStream<String> {
        let styleContext = learningStyleTags.isEmpty
            ? ""
            : "The student has indicated: \(learningStyleTags.joined(separator: ", ")). Adapt your communication style accordingly."
        
        let prevContext = previousAdvice.isEmpty
            ? ""
            : "\nPrevious advice this session:\n" + previousAdvice.map { "- \($0.topic): \($0.summary)" }.joined(separator: "\n")
        
        let systemPrompt = """
        You are Spark, a warm and patient AI tutor helping a \(gradeLevel) grade student.
        Your tone is encouraging, never judgmental. You explain concepts step by step.
        \(styleContext)
        
        You will receive an image of the student's handwritten work. Read it carefully — \
        including all math notation, diagrams, symbols, and spatial layout.
        
        Respond ONLY with valid JSON in EXACTLY this field order (speech first):
        {
          "speech": "Your spoken feedback (2-3 warm, encouraging sentences). Output this field FIRST.",
          "annotations": [
            {
              "type": "circle" | "arrow" | "write",
              "target_region": {"x": 0.0-1.0, "y": 0.0-1.0, "radius": 0.01-0.05},
              "from": {"x": 0.0-1.0, "y": 0.0-1.0},
              "to": {"x": 0.0-1.0, "y": 0.0-1.0},
              "text": "correction text (for write type only)",
              "position": {"x": 0.0-1.0, "y": 0.0-1.0},
              "color": "#2BBFB3" for guidance | "#5B8AF5" for corrections | "#E05C5C" for errors,
              "label": "optional short label"
            }
          ],
          "advice_entry": {
            "topic": "Short topic name",
            "summary": "1-2 sentence summary",
            "full_advice": "Full explanation for the student's notes",
            "concept_key": "subject.topic.subtopic"
          }
        }
        
        Coordinates are 0.0-1.0 fractions of the canvas (origin top-left).
        Use circle to highlight regions, arrow to connect two points, \
        write to place a text correction at a specific position.
        Keep annotations to 3 or fewer — clarity over quantity.
        If the canvas appears blank, greet the student and offer an opening question \
        based on the assignment context.
        """

        let userContent: [[String: Any]] = [
            [
                "type": "image",
                "source": [
                    "type": "base64",
                    "media_type": "image/jpeg",
                    "data": studentImageBase64
                ]
            ],
            [
                "type": "text",
                "text": "Assignment context: \(assignmentContext)\n\(prevContext)\n\nAnalyze the student's handwritten work shown in the image and provide feedback with annotations."
            ]
        ]

        return try await makeStreamingRequest(systemPrompt: systemPrompt, userContent: userContent)
    }
    
    // MARK: - Session Concept Analysis (batch — no streaming needed)
    
    func analyzeSessionConcepts(adviceLog: [AdviceSummary]) async throws -> ConceptAnalysisResult {
        let systemPrompt = """
        You are analyzing a tutoring session's advice log to identify concept strengths and struggles.
        Respond ONLY with valid JSON:
        {
          "strengths": [{"concept_key": "subject.topic.subtopic", "label": "Human Readable Name", "subject": "math|reading|writing|science|history|foreignLanguage|other"}],
          "struggles": [{"concept_key": "subject.topic.subtopic", "label": "Human Readable Name", "subject": "math|reading|writing|science|history|foreignLanguage|other"}]
        }
        """
        
        let logSummary = adviceLog.map { "Topic: \($0.topic)\nSummary: \($0.summary)\nFull: \($0.fullAdvice)" }.joined(separator: "\n---\n")
        
        let userMessage = "Analyze this session's advice log and extract concept strengths and struggles:\n\n\(logSummary)"
        
        let responseText = try await makeRequest(systemPrompt: systemPrompt, userMessage: userMessage)
        let jsonText = extractJSON(from: responseText)
        guard let jsonData = jsonText.data(using: .utf8) else {
            throw ClaudeError.invalidResponse
        }
        
        return try JSONDecoder().decode(ConceptAnalysisResult.self, from: jsonData)
    }
    
    // MARK: - Lesson Plan Generation (batch)
    
    func generateLessonPlan(
        conceptKey: String,
        conceptLabel: String,
        subject: String,
        gradeLevel: String,
        learningStyleTags: [String]
    ) async throws -> [LessonStep] {
        let systemPrompt = """
        You are Spark, an AI tutor generating a structured lesson plan for a \(gradeLevel) grade student.
        The student's learning preferences: \(learningStyleTags.joined(separator: ", "))
        
        Create a lesson plan with 3-4 steps. Respond ONLY with valid JSON array:
        [
          {
            "title": "Step title",
            "type": "conceptExplanation" | "workedExample" | "practiceProblem" | "reviewChallenge",
            "explanation_text": "Detailed explanation for this step",
            "problem_text": "Optional problem for practice steps",
            "hint_text": "Optional hint"
          }
        ]
        
        Step 1 should always be conceptExplanation. Include at least one practiceProblem.
        Use warm, encouraging language appropriate for the grade level.
        """
        
        let userMessage = "Generate a lesson plan for concept: \(conceptLabel) (\(conceptKey)) in subject: \(subject)"
        
        let responseText = try await makeRequest(systemPrompt: systemPrompt, userMessage: userMessage)
        let jsonText = extractJSON(from: responseText)
        guard let jsonData = jsonText.data(using: .utf8) else {
            throw ClaudeError.invalidResponse
        }
        
        struct RawStep: Codable {
            var title: String
            var type: String
            var explanation_text: String
            var problem_text: String?
            var hint_text: String?
        }
        
        let rawSteps = try JSONDecoder().decode([RawStep].self, from: jsonData)
        
        return rawSteps.enumerated().map { index, raw in
            LessonStep(
                index: index,
                title: raw.title,
                type: LessonStepType(rawValue: raw.type) ?? .conceptExplanation,
                explanationText: raw.explanation_text,
                problemText: raw.problem_text,
                hintText: raw.hint_text
            )
        }
    }
    
    // MARK: - Encouragement (batch)
    
    func generateEncouragement(
        studentName: String,
        gradeLevel: String,
        recentStrengths: [String],
        recentStruggles: [String],
        streakCount: Int
    ) async throws -> String {
        let systemPrompt = """
        You are Spark, a warm AI tutor. Generate a brief (1-2 sentence) personalized encouragement message for the student's dashboard.
        Reference their recent progress specifically. Be warm, genuine, and motivating. No emojis. Keep it under 30 words.
        """
        
        let userMessage = """
        Student: \(studentName), Grade: \(gradeLevel)
        Streak: \(streakCount) days
        Recent strengths: \(recentStrengths.joined(separator: ", "))
        Recent struggles: \(recentStruggles.joined(separator: ", "))
        """
        
        return try await makeRequest(systemPrompt: systemPrompt, userMessage: userMessage)
    }
    
    // MARK: - Hint Generation (batch, vision input)
    
    func generateHint(
        conceptLabel: String,
        stepExplanation: String,
        problemText: String,
        studentImageBase64: String,
        gradeLevel: String
    ) async throws -> String {
        let systemPrompt = """
        You are Spark, a warm AI tutor. Give a brief, helpful hint (1-2 sentences) to guide the student \
        without giving away the answer. Grade level: \(gradeLevel). Be encouraging.
        You will receive an image of the student's handwritten work. Read it carefully.
        """

        let userContent: [[String: Any]] = [
            [
                "type": "image",
                "source": [
                    "type": "base64",
                    "media_type": "image/jpeg",
                    "data": studentImageBase64
                ]
            ],
            [
                "type": "text",
                "text": """
                Concept: \(conceptLabel)
                Problem: \(problemText)
                Context: \(stepExplanation)
                
                The student's current work is shown in the image above. Give a gentle hint.
                """
            ]
        ]

        return try await makeRequestWithContent(systemPrompt: systemPrompt, userContent: userContent)
    }
    
    // MARK: - Check Answer (batch, vision input)
    
    func checkAnswer(
        conceptLabel: String,
        problemText: String,
        studentImageBase64: String,
        gradeLevel: String
    ) async throws -> (feedback: String, result: StepGradeResult) {
        let systemPrompt = """
        You are Spark, a warm AI tutor checking a student's answer. Grade level: \(gradeLevel).
        You will receive an image of the student's handwritten answer. Read it carefully.
        Respond ONLY with valid JSON:
        {
          "feedback": "Your feedback (2-3 sentences, warm and specific)",
          "result": "pass" | "partialPass" | "needsRetry"
        }
        """

        let userContent: [[String: Any]] = [
            [
                "type": "image",
                "source": [
                    "type": "base64",
                    "media_type": "image/jpeg",
                    "data": studentImageBase64
                ]
            ],
            [
                "type": "text",
                "text": """
                Concept: \(conceptLabel)
                Problem: \(problemText)
                
                The student's answer is shown in the image above. Check it and provide feedback.
                """
            ]
        ]

        let responseText = try await makeRequestWithContent(systemPrompt: systemPrompt, userContent: userContent)
        let jsonText = extractJSON(from: responseText)
        guard let jsonData = jsonText.data(using: .utf8) else {
            throw ClaudeError.invalidResponse
        }
        
        struct CheckResult: Codable {
            var feedback: String
            var result: String
        }
        
        let parsed = try JSONDecoder().decode(CheckResult.self, from: jsonData)
        let gradeResult = StepGradeResult(rawValue: parsed.result) ?? .needsRetry
        
        return (parsed.feedback, gradeResult)
    }
    
    // MARK: - Helpers
    
    private func extractJSON(from text: String) -> String {
        if let range = text.range(of: "```json") {
            let start = range.upperBound
            if let end = text.range(of: "```", range: start..<text.endIndex) {
                return String(text[start..<end.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        if let range = text.range(of: "```") {
            let start = range.upperBound
            if let end = text.range(of: "```", range: start..<text.endIndex) {
                return String(text[start..<end.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
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
}

enum ClaudeError: LocalizedError {
    case noAPIKey
    case apiError(String)
    case invalidResponse
    
    var errorDescription: String? {
        switch self {
        case .noAPIKey:
            return "No API key configured. Add your Claude API key in Settings."
        case .apiError(let msg):
            return "API Error: \(msg)"
        case .invalidResponse:
            return "Could not parse the AI response."
        }
    }
}

extension ClaudeAPIClient {
    func setAPIKey(_ key: String) {
        apiKey = key
    }
}
