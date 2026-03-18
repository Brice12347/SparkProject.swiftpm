import SwiftUI
import PencilKit

// R6: Lightweight manager for debounced canvas analysis during lessons.
// Holds the debounce task and fires checkAnswer or generateHint after 4 s of inactivity.
@MainActor
class LessonCanvasManager: ObservableObject {
    @Published var autoFeedback: String = ""
    @Published var autoHint: String = ""
    @Published var showAutoHint: Bool = false

    private var debounceTask: Task<Void, Never>?

    func onCanvasChanged(
        _ drawing: PKDrawing,
        step: LessonStep?,
        conceptLabel: String,
        gradeLevel: String
    ) {
        debounceTask?.cancel()
        guard let step = step, !drawing.strokes.isEmpty else { return }

        debounceTask = Task {
            try? await Task.sleep(nanoseconds: 4_000_000_000)
            guard !Task.isCancelled else { return }

            let bounds = drawing.bounds.isEmpty
                ? CGRect(x: 0, y: 0, width: 1024, height: 512)
                : drawing.bounds.insetBy(dx: -20, dy: -20)
            let image = drawing.image(from: bounds, scale: 1.5)
            guard let jpegData = image.jpegData(compressionQuality: 0.7) else { return }
            let base64 = jpegData.base64EncodedString()

            do {
                switch step.type {
                case .practiceProblem, .reviewChallenge:
                    let (fb, _) = try await ClaudeAPIClient.shared.checkAnswer(
                        conceptLabel: conceptLabel,
                        problemText: step.problemText ?? "",
                        studentImageBase64: base64,
                        gradeLevel: gradeLevel
                    )
                    self.autoFeedback = fb
                    SpeechService.shared.speak(fb)

                case .conceptExplanation, .workedExample:
                    let hint = try await ClaudeAPIClient.shared.generateHint(
                        conceptLabel: conceptLabel,
                        stepExplanation: step.explanationText,
                        problemText: step.problemText ?? "",
                        studentImageBase64: base64,
                        gradeLevel: gradeLevel
                    )
                    self.autoHint = hint
                    self.showAutoHint = true
                    SpeechService.shared.speak(hint)
                }
            } catch {
                // Auto-feedback failures are non-critical; student can still use manual buttons
            }
        }
    }

    func cancel() {
        debounceTask?.cancel()
    }
}

struct LessonSessionView: View {
    let plan: LessonPlan
    let student: Student

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var studentDrawing = PKDrawing()
    @State private var currentStepIndex: Int
    @State private var showHint = false
    @State private var hintText = ""
    @State private var feedback = ""
    @State private var isChecking = false
    @State private var isComplete = false
    @State private var showConfetti = false

    @StateObject private var canvasManager = LessonCanvasManager()

    init(plan: LessonPlan, student: Student) {
        self.plan = plan
        self.student = student
        self._currentStepIndex = State(initialValue: plan.currentStepIndex)
    }

    private var steps: [LessonStep] { plan.steps }
    private var currentStep: LessonStep? {
        guard currentStepIndex < steps.count else { return nil }
        return steps[currentStepIndex]
    }

    var body: some View {
        ZStack {
            SparkTheme.background(colorScheme).ignoresSafeArea()

            VStack(spacing: 0) {
                lessonTopBar
                progressIndicator
                
                ScrollView {
                    VStack(spacing: SparkTheme.spacingLG) {
                        if let step = currentStep {
                            lessonCard(step)

                            if step.type == .practiceProblem || step.type == .reviewChallenge {
                                practiceArea(step)
                            }

                            if step.type == .conceptExplanation || step.type == .workedExample {
                                SparkButton(title: "Next Step →", style: .primary) {
                                    advanceStep(result: .pass)
                                }
                            }
                        }

                        if !feedback.isEmpty {
                            feedbackCard
                        }

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, SparkTheme.spacingMD)
                    .padding(.top, SparkTheme.spacingMD)
                }
            }

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    encouragementBubble
                        .padding(.trailing, 20)
                        .padding(.bottom, 20)
                }
            }

            if showConfetti {
                ConfettiView()
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
        }
        .navigationBarHidden(true)
        .alert("Lesson Complete!", isPresented: $isComplete) {
            Button("Back to Lessons") { dismiss() }
        } message: {
            Text("Great work! You've completed this lesson on \(plan.conceptLabel).")
        }
        // R6: Bridge auto-feedback from LessonCanvasManager into existing state
        .onChange(of: canvasManager.autoFeedback) { _, newValue in
            guard !newValue.isEmpty else { return }
            feedback = newValue
        }
        .onChange(of: canvasManager.showAutoHint) { _, show in
            guard show else { return }
            hintText = canvasManager.autoHint
            withAnimation { showHint = true }
            canvasManager.showAutoHint = false
        }
    }

    // MARK: - Top Bar

    private var lessonTopBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                    Text(plan.conceptLabel)
                        .font(SparkTypography.bodyMedium)
                }
                .foregroundStyle(SparkTheme.textPrimary(colorScheme))
            }

            Spacer()

            Text("Step \(currentStepIndex + 1) of \(steps.count)")
                .font(SparkTypography.caption)
                .foregroundStyle(SparkTheme.gray500)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Progress

    private var progressIndicator: some View {
        VStack(spacing: 8) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(SparkTheme.gray200)
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(SparkTheme.teal)
                        .frame(
                            width: geo.size.width * CGFloat(currentStepIndex) / CGFloat(max(steps.count, 1)),
                            height: 8
                        )
                        .animation(.spring(response: 0.5), value: currentStepIndex)
                }

                HStack(spacing: 0) {
                    ForEach(0..<steps.count, id: \.self) { index in
                        Circle()
                            .fill(index <= currentStepIndex ? SparkTheme.teal : SparkTheme.gray300)
                            .frame(width: 10, height: 10)
                            .frame(maxWidth: .infinity)
                    }
                }
                .offset(y: -1)
            }
            .frame(height: 10)
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Lesson Card

    private func lessonCard(_ step: LessonStep) -> some View {
        SparkCard(cornerRadius: SparkTheme.radiusXL) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 8) {
                    Image(systemName: stepIcon(step.type))
                        .font(.system(size: 16))
                        .foregroundStyle(SparkTheme.teal)
                    Text(step.title)
                        .font(SparkTypography.heading2)
                        .foregroundStyle(SparkTheme.textPrimary(colorScheme))
                }

                Text(step.explanationText)
                    .font(SparkTypography.bodyLarge)
                    .foregroundStyle(SparkTheme.textPrimary(colorScheme))
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(4)

                if let problem = step.problemText {
                    VStack(alignment: .leading, spacing: 8) {
                        Divider()
                        Text("Problem:")
                            .font(SparkTypography.captionBold)
                            .foregroundStyle(SparkTheme.teal)
                        Text(problem)
                            .font(SparkTypography.bodyMedium)
                            .foregroundStyle(SparkTheme.textPrimary(colorScheme))
                    }
                }
            }
        }
    }

    private func stepIcon(_ type: LessonStepType) -> String {
        switch type {
        case .conceptExplanation: return "book.fill"
        case .workedExample: return "pencil.and.outline"
        case .practiceProblem: return "pencil.tip"
        case .reviewChallenge: return "star.fill"
        }
    }

    // MARK: - Practice Area

    private func practiceArea(_ step: LessonStep) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your turn:")
                .font(SparkTypography.heading3)
                .foregroundStyle(SparkTheme.textPrimary(colorScheme))

            CanvasView(
                drawing: $studentDrawing,
                aiDrawing: PKDrawing(),
                aiAnnotations: [],
                assignmentImage: nil,
                backgroundColor: UIColor(SparkTheme.canvasWhite),
                selectedColor: UIColor(SparkTheme.charcoal),
                lineWidth: 1.5,
                isEraser: false,
                onCanvasChanged: { drawing in
                    canvasManager.onCanvasChanged(
                        drawing,
                        step: currentStep,
                        conceptLabel: plan.conceptLabel,
                        gradeLevel: student.gradeLevel
                    )
                }
            )
            .frame(minHeight: 220)
            .clipShape(
                RoundedRectangle(cornerRadius: SparkTheme.radiusLG, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: SparkTheme.radiusLG, style: .continuous)
                    .strokeBorder(SparkTheme.gray300, lineWidth: 1.5)
            )

            if showHint && !hintText.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundStyle(SparkTheme.practiceAmber)
                    Text(hintText)
                        .font(SparkTypography.body)
                        .foregroundStyle(SparkTheme.textPrimary(colorScheme))
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: SparkTheme.radiusMD, style: .continuous)
                        .fill(SparkTheme.practiceAmber.opacity(0.1))
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            HStack(spacing: 14) {
                SparkButton(title: "💡 Hint", style: .ghost, isFullWidth: false) {
                    requestHint(step)
                }

                SparkButton(title: "Check Answer ✦", style: .primary, isFullWidth: true) {
                    checkAnswer(step)
                }
                .overlay {
                    if isChecking {
                        ProgressView()
                            .tint(.white)
                    }
                }
            }
        }
    }

    // MARK: - Feedback Card

    private var feedbackCard: some View {
        SparkCard {
            HStack(alignment: .top, spacing: 12) {
                Text("✦")
                    .font(.system(size: 20))
                    .foregroundStyle(SparkTheme.teal)

                Text(feedback)
                    .font(SparkTypography.body)
                    .foregroundStyle(SparkTheme.textPrimary(colorScheme))
            }
        }
    }

    // MARK: - Encouragement Bubble

    private var encouragementBubble: some View {
        let messages = [
            "You've got this! ✦",
            "Almost there!",
            "Try it — there's no wrong attempt.",
            "Take your time!",
            "Keep going!"
        ]
        let message = messages[currentStepIndex % messages.count]

        return HStack(spacing: 8) {
            Text("⭐️")
                .font(.system(size: 28))

            Text(message)
                .font(SparkTypography.caption)
                .foregroundStyle(SparkTheme.textPrimary(colorScheme))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule().fill(SparkTheme.surface(colorScheme))
                        .shadow(color: SparkTheme.cardShadow(colorScheme), radius: 6, y: 2)
                )
        }
    }

    // MARK: - Actions

    private func requestHint(_ step: LessonStep) {
        canvasManager.cancel()
        Task {
            do {
                let bounds = studentDrawing.bounds.isEmpty
                    ? CGRect(x: 0, y: 0, width: 1024, height: 512)
                    : studentDrawing.bounds.insetBy(dx: -20, dy: -20)
                let image = studentDrawing.image(from: bounds, scale: 1.5)
                guard let jpegData = image.jpegData(compressionQuality: 0.7) else { return }
                let base64 = jpegData.base64EncodedString()

                let hint = try await ClaudeAPIClient.shared.generateHint(
                    conceptLabel: plan.conceptLabel,
                    stepExplanation: step.explanationText,
                    problemText: step.problemText ?? "",
                    studentImageBase64: base64,
                    gradeLevel: student.gradeLevel
                )
                withAnimation {
                    hintText = hint
                    showHint = true
                }
                SpeechService.shared.speak(hint)
            } catch {
                hintText = step.hintText ?? "Think about what you've learned in the explanation above."
                withAnimation { showHint = true }
            }
        }
    }

    private func checkAnswer(_ step: LessonStep) {
        canvasManager.cancel()
        isChecking = true
        Task {
            do {
                let bounds = studentDrawing.bounds.isEmpty
                    ? CGRect(x: 0, y: 0, width: 1024, height: 512)
                    : studentDrawing.bounds.insetBy(dx: -20, dy: -20)
                let image = studentDrawing.image(from: bounds, scale: 1.5)
                guard let jpegData = image.jpegData(compressionQuality: 0.7) else {
                    isChecking = false
                    return
                }
                let base64 = jpegData.base64EncodedString()

                let (resultFeedback, result) = try await ClaudeAPIClient.shared.checkAnswer(
                    conceptLabel: plan.conceptLabel,
                    problemText: step.problemText ?? "",
                    studentImageBase64: base64,
                    gradeLevel: student.gradeLevel
                )

                feedback = resultFeedback
                SpeechService.shared.speak(resultFeedback)

                if result == .pass || result == .partialPass {
                    advanceStep(result: result)
                }
            } catch {
                feedback = "I had trouble checking your answer. Try again!"
            }
            isChecking = false
        }
    }

    private func advanceStep(result: StepGradeResult) {
        canvasManager.cancel()
        let service = LessonPlanService(modelContext: modelContext)
        service.markStepComplete(plan: plan, stepIndex: currentStepIndex, result: result)

        if plan.isComplete {
            showConfetti = true
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)

            let profileService = StudentProfileService(modelContext: modelContext)
            profileService.advanceToDeveloping(studentId: student.id, conceptKey: plan.conceptKey)

            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                isComplete = true
            }
        } else {
            withAnimation(.spring(response: 0.5)) {
                currentStepIndex += 1
                studentDrawing = PKDrawing()
                feedback = ""
                showHint = false
                hintText = ""
            }
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        }
    }
}
