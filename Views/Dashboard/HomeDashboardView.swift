import SwiftUI
import SwiftData

struct HomeDashboardView: View {
    let student: Student
    @Environment(\.colorScheme) private var colorScheme
    @Query(sort: \HomeworkSession.startedAt, order: .reverse) private var sessions: [HomeworkSession]
    @Query private var conceptProfiles: [ConceptProfile]
    @State private var encouragementMessage: String = ""
    @State private var showSettings = false

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<21: return "Good evening"
        default: return "Hey there"
        }
    }

    private var recentSessions: [HomeworkSession] {
        sessions.filter { $0.studentId == student.id }.prefix(5).map { $0 }
    }

    private var recommendedConcepts: [ConceptProfile] {
        conceptProfiles
            .filter { $0.studentId == student.id && ($0.proficiencyLevel == 2 || $0.proficiencyLevel == 3) }
            .prefix(4)
            .map { $0 }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: SparkTheme.spacingLG) {
                headerSection
                encouragementBanner
                recentAssignmentsSection
                recommendedSection
                Spacer(minLength: 20)
            }
            .padding(.horizontal, SparkTheme.spacingMD)
            .padding(.top, SparkTheme.spacingSM)
        }
        .background(SparkTheme.background(colorScheme).ignoresSafeArea())
        .navigationBarHidden(true)
        .sheet(isPresented: $showSettings) {
            SettingsView(student: student)
        }
        .onAppear {
            loadEncouragement()
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(alignment: .center) {
            HStack(spacing: 12) {
                AvatarView(emoji: student.avatarEmoji, size: 48)

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(greeting), \(student.name)!")
                        .font(SparkTypography.heading2)
                        .foregroundStyle(SparkTheme.textPrimary(colorScheme))

                    if !encouragementMessage.isEmpty {
                        Text(encouragementMessage)
                            .font(SparkTypography.caption)
                            .foregroundStyle(SparkTheme.textSecondary(colorScheme))
                            .lineLimit(1)
                    }
                }
            }

            Spacer()

            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(SparkTheme.textSecondary(colorScheme))
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Settings")
        }
    }

    // MARK: - Encouragement Banner

    private var encouragementBanner: some View {
        SparkCard(cornerRadius: SparkTheme.radiusLG) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Text("✦")
                            .foregroundStyle(SparkTheme.teal)
                        Text("Your Spark Update")
                            .font(SparkTypography.captionBold)
                            .foregroundStyle(SparkTheme.teal)
                    }

                    Text(encouragementText)
                        .font(SparkTypography.body)
                        .foregroundStyle(SparkTheme.textPrimary(colorScheme))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                if student.streakCount > 0 {
                    VStack(spacing: 4) {
                        Text("🔥")
                            .font(.system(size: 28))
                        Text("\(student.streakCount)")
                            .font(SparkTypography.heading3)
                            .foregroundStyle(SparkTheme.teal)
                        Text("day streak")
                            .font(SparkTypography.label)
                            .foregroundStyle(SparkTheme.textSecondary(colorScheme))
                    }
                }
            }
        }
    }

    private var encouragementText: String {
        if !encouragementMessage.isEmpty { return encouragementMessage }
        if recentSessions.isEmpty {
            return "Welcome to Spark! Upload your first assignment and let's get started."
        }
        return "Keep up the great work, \(student.name)! Every session makes you stronger."
    }

    // MARK: - Recent Assignments

    private var recentAssignmentsSection: some View {
        VStack(alignment: .leading, spacing: SparkTheme.spacingSM) {
            HStack {
                Text("Recent Assignments")
                    .font(SparkTypography.heading3)
                    .foregroundStyle(SparkTheme.textPrimary(colorScheme))
                Spacer()
            }

            if recentSessions.isEmpty {
                emptyAssignmentsCard
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(recentSessions, id: \.id) { session in
                            assignmentCard(session)
                        }
                    }
                }
            }
        }
    }

    private var emptyAssignmentsCard: some View {
        SparkCard {
            VStack(spacing: 12) {
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(SparkTheme.gray400)
                Text("No assignments yet")
                    .font(SparkTypography.bodyMedium)
                    .foregroundStyle(SparkTheme.textSecondary(colorScheme))
                Text("Upload your first homework to get started!")
                    .font(SparkTypography.caption)
                    .foregroundStyle(SparkTheme.gray500)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
    }

    private func assignmentCard(_ session: HomeworkSession) -> some View {
        SparkCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(SparkTheme.subjectColor(session.subject))
                        .frame(width: 12, height: 12)
                    Text(session.subject.displayName)
                        .font(SparkTypography.label)
                        .foregroundStyle(SparkTheme.textSecondary(colorScheme))
                }

                Text(session.displayName)
                    .font(SparkTypography.bodyMedium)
                    .foregroundStyle(SparkTheme.textPrimary(colorScheme))
                    .lineLimit(2)

                Text(session.formattedDate)
                    .font(SparkTypography.caption)
                    .foregroundStyle(SparkTheme.gray500)

                HStack(spacing: 8) {
                    if let tag = session.performanceTag {
                        performanceChip(tag)
                    }

                    if session.adviceEntryCount > 0 {
                        HStack(spacing: 3) {
                            Text("✦")
                                .font(.system(size: 10))
                            Text("\(session.adviceEntryCount) tips")
                                .font(SparkTypography.label)
                        }
                        .foregroundStyle(SparkTheme.teal)
                    }
                }
            }
        }
        .frame(width: 200)
    }

    private func performanceChip(_ tag: PerformanceTag) -> some View {
        let color: Color = {
            switch tag {
            case .great: return SparkTheme.strengthGreen
            case .keepPracticing: return SparkTheme.practiceAmber
            case .needsReview: return SparkTheme.struggleRed
            }
        }()

        return Text(tag.displayName)
            .font(SparkTypography.label)
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }

    // MARK: - Recommended

    private var recommendedSection: some View {
        VStack(alignment: .leading, spacing: SparkTheme.spacingSM) {
            Text("Recommended for You")
                .font(SparkTypography.heading3)
                .foregroundStyle(SparkTheme.textPrimary(colorScheme))

            if recommendedConcepts.isEmpty {
                SparkCard {
                    VStack(spacing: 12) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 36))
                            .foregroundStyle(SparkTheme.teal)
                        Text("Complete a session to get personalized recommendations")
                            .font(SparkTypography.body)
                            .foregroundStyle(SparkTheme.textSecondary(colorScheme))
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                    ForEach(recommendedConcepts, id: \.id) { concept in
                        conceptCard(concept)
                    }
                }
            }
        }
    }

    private func conceptCard(_ concept: ConceptProfile) -> some View {
        SparkCard {
            VStack(alignment: .leading, spacing: 10) {
                Circle()
                    .fill(SparkTheme.subjectColor(concept.subject))
                    .frame(width: 10, height: 10)

                Text(concept.label)
                    .font(SparkTypography.bodyMedium)
                    .foregroundStyle(SparkTheme.textPrimary(colorScheme))
                    .lineLimit(2)

                Text("Level \(concept.proficiencyLevel)/5")
                    .font(SparkTypography.caption)
                    .foregroundStyle(SparkTheme.textSecondary(colorScheme))

                Text("Start Lesson →")
                    .font(SparkTypography.captionBold)
                    .foregroundStyle(SparkTheme.teal)
            }
        }
    }

    private func loadEncouragement() {
        if recentSessions.count > 0 {
            let subjects = Set(recentSessions.prefix(3).map { $0.subject.displayName })
            encouragementMessage = "You've been working hard on \(subjects.joined(separator: " and "))!"
        }
    }
}
