import SwiftUI
import PencilKit

struct LiveSessionView: View {
    let student: Student
    let subject: Subject
    let assignmentName: String?
    let assignmentImage: UIImage?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext

    @StateObject private var sessionManager = TutorSessionManager()

    @State private var studentDrawing = PKDrawing()
    @State private var showSidebar = false
    @State private var showPostSession = false
    @State private var hideAINotes = false
    @State private var elapsedSeconds = 0
    @State private var timer: Timer?

    private var sessionTitle: String {
        assignmentName ?? "\(subject.displayName) Session"
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                topBar
                sessionContent
            }
            .background(SparkTheme.background(colorScheme).ignoresSafeArea())

            // Session Notes Pull Tab
            if !showSidebar {
                pullTab
            }

            // Sidebar Overlay
            if showSidebar {
                sidebarOverlay
            }
        }
        .statusBarHidden(true)
        .onAppear(perform: startSession)
        .onDisappear(perform: cleanup)
        .fullScreenCover(isPresented: $showPostSession) {
            PostSessionSummaryView(
                session: sessionManager.currentSession,
                adviceLog: sessionManager.adviceLog,
                onDismiss: { dismiss() }
            )
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack(spacing: 16) {
            Button {
                endSession()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                    Text(sessionTitle)
                        .font(SparkTypography.bodyMedium)
                }
                .foregroundStyle(SparkTheme.textPrimary(colorScheme))
            }
            .accessibilityLabel("Exit session")

            // Subject color bar
            RoundedRectangle(cornerRadius: 2)
                .fill(SparkTheme.subjectColor(subject))
                .frame(height: 4)

            Spacer()

            Toggle(isOn: $hideAINotes) {
                Text("Hide AI Notes")
                    .font(SparkTypography.caption)
            }
            .toggleStyle(.switch)
            .tint(SparkTheme.teal)
            .fixedSize()

            Text(formattedTime)
                .font(SparkTypography.caption)
                .foregroundStyle(SparkTheme.gray500)
                .monospacedDigit()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(SparkTheme.surface(colorScheme))
    }

    private var formattedTime: String {
        let min = elapsedSeconds / 60
        let sec = elapsedSeconds % 60
        return String(format: "%d:%02d", min, sec)
    }

    // MARK: - Session Content (iPad Landscape Split)

    private var sessionContent: some View {
        GeometryReader { geo in
            let isLandscape = geo.size.width > geo.size.height
            let canvasWidth = isLandscape ? geo.size.width * 0.75 : geo.size.width
            let tutorWidth = isLandscape ? geo.size.width * 0.25 : geo.size.width

            if isLandscape {
                HStack(spacing: 0) {
                    canvasPanel
                        .frame(width: canvasWidth)

                    Divider()

                    TutorPanelView(
                        sessionManager: sessionManager,
                        onHelpMe: {
                            Task { await sessionManager.onHelpMeRequested() }
                        },
                        onDone: { endSession() }
                    )
                    .frame(width: tutorWidth)
                }
            } else {
                VStack(spacing: 0) {
                    canvasPanel
                        .frame(maxHeight: geo.size.height * 0.65)

                    Divider()

                    TutorPanelView(
                        sessionManager: sessionManager,
                        onHelpMe: {
                            Task { await sessionManager.onHelpMeRequested() }
                        },
                        onDone: { endSession() }
                    )
                }
            }
        }
    }

    // MARK: - Canvas Panel

    private var canvasPanel: some View {
        ZStack(alignment: .topLeading) {
            CanvasView(
                drawing: $studentDrawing,
                aiDrawing: hideAINotes ? PKDrawing() : sessionManager.aiDrawing,
                backgroundColor: UIColor(SparkTheme.canvasWhite),
                onCanvasChanged: {
                    sessionManager.onCanvasChanged(drawing: studentDrawing)
                }
            )

            // AI Badges on annotations
            if !hideAINotes && !sessionManager.pendingAnnotations.isEmpty {
                aiBadge
                    .padding(12)
            }
        }
    }

    private var aiBadge: some View {
        HStack(spacing: 4) {
            Text("✦")
                .font(.system(size: 10))
            Text("AI")
                .font(SparkTypography.label)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(SparkTheme.teal.opacity(0.9))
        .clipShape(Capsule())
    }

    // MARK: - Pull Tab

    private var pullTab: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                        showSidebar = true
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 10, weight: .bold))
                        Text("Session\nNotes")
                            .font(.system(size: 9, weight: .semibold))
                            .multilineTextAlignment(.center)
                    }
                    .foregroundStyle(.white)
                    .frame(width: 28, height: 80)
                    .background(SparkTheme.teal)
                    .clipShape(
                        UnevenRoundedRectangle(
                            topLeadingRadius: 12,
                            bottomLeadingRadius: 12,
                            bottomTrailingRadius: 0,
                            topTrailingRadius: 0
                        )
                    )
                }
                .accessibilityLabel("Open session notes")
            }
            Spacer()
        }
    }

    // MARK: - Sidebar Overlay

    private var sidebarOverlay: some View {
        GeometryReader { geo in
            HStack(spacing: 0) {
                Spacer()

                SessionNotesSidebar(
                    adviceLog: sessionManager.adviceLog,
                    onClose: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                            showSidebar = false
                        }
                    },
                    onReaction: { advice, reaction in
                        sessionManager.setReaction(for: advice, reaction: reaction)
                    }
                )
                .frame(width: min(geo.size.width * 0.35, 380))
                .clipShape(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 20,
                        bottomLeadingRadius: 20,
                        bottomTrailingRadius: 0,
                        topTrailingRadius: 0
                    )
                )
                .shadow(color: Color.black.opacity(0.12), radius: 20, x: -4)
                .transition(.move(edge: .trailing))
            }
        }
    }

    // MARK: - Session Lifecycle

    private func startSession() {
        sessionManager.startSession(
            student: student,
            subject: subject,
            assignmentName: assignmentName,
            assignmentImage: assignmentImage,
            modelContext: modelContext
        )

        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            elapsedSeconds += 1
        }
    }

    private func endSession() {
        timer?.invalidate()
        Task {
            await sessionManager.endSession()
            showPostSession = true
        }
    }

    private func cleanup() {
        timer?.invalidate()
    }
}
