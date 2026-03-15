import SwiftUI
import SwiftData

struct StudentProfileView: View {
    let student: Student
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \HomeworkSession.startedAt, order: .reverse) private var allSessions: [HomeworkSession]
    @Query private var allConcepts: [ConceptProfile]

    private var sessions: [HomeworkSession] {
        allSessions.filter { $0.studentId == student.id }
    }

    private var strengths: [ConceptProfile] {
        allConcepts.filter { $0.studentId == student.id && $0.proficiencyLevel >= 4 }
    }

    private var growing: [ConceptProfile] {
        allConcepts.filter { $0.studentId == student.id && $0.proficiencyLevel >= 1 && $0.proficiencyLevel <= 3 }
    }

    private var radarData: [SubjectSkillLevel] {
        let profileService = StudentProfileService(modelContext: modelContext)
        return profileService.skillsRadarData(studentId: student.id)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: SparkTheme.spacingLG) {
                profileHeader
                streakWidget
                skillsRadar
                conceptSections
                assignmentTimeline
                Spacer(minLength: 20)
            }
        }
        .background(SparkTheme.background(colorScheme).ignoresSafeArea())
        .navigationBarHidden(true)
    }

    // MARK: - Profile Header

    private var profileHeader: some View {
        VStack(spacing: 16) {
            ZStack {
                (colorScheme == .dark ? SparkTheme.profileGradientDark : SparkTheme.profileGradient)
                    .frame(height: 180)

                VStack(spacing: 12) {
                    AvatarView(emoji: student.avatarEmoji, size: 72, borderColor: .white, borderWidth: 3)
                    Text(student.name)
                        .font(SparkTypography.heading1)
                        .foregroundStyle(SparkTheme.textPrimary(colorScheme))
                    Text("Grade \(student.gradeLevel)")
                        .font(SparkTypography.body)
                        .foregroundStyle(SparkTheme.textSecondary(colorScheme))
                }
            }
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: 0,
                    bottomLeadingRadius: SparkTheme.radiusXXL,
                    bottomTrailingRadius: SparkTheme.radiusXXL,
                    topTrailingRadius: 0
                )
            )
        }
    }

    // MARK: - Streak Widget

    private var streakWidget: some View {
        SparkCard {
            HStack(spacing: 20) {
                ZStack {
                    Circle()
                        .stroke(SparkTheme.gray200, lineWidth: 8)
                        .frame(width: 80, height: 80)

                    Circle()
                        .trim(from: 0, to: min(CGFloat(student.streakCount) / 7.0, 1.0))
                        .stroke(SparkTheme.teal, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 0) {
                        Text("\(student.streakCount)")
                            .font(SparkTypography.display)
                            .foregroundStyle(SparkTheme.teal)
                        Text("days")
                            .font(SparkTypography.label)
                            .foregroundStyle(SparkTheme.gray500)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Study Streak")
                        .font(SparkTypography.heading3)
                        .foregroundStyle(SparkTheme.textPrimary(colorScheme))

                    HStack(spacing: 6) {
                        ForEach(0..<7, id: \.self) { day in
                            Text(day < student.streakCount ? "🔥" : "○")
                                .font(.system(size: day < student.streakCount ? 18 : 14))
                                .foregroundStyle(SparkTheme.gray400)
                        }
                    }
                }

                Spacer()
            }
        }
        .padding(.horizontal, SparkTheme.spacingMD)
    }

    // MARK: - Skills Radar

    private var skillsRadar: some View {
        SparkCard {
            VStack(spacing: 12) {
                Text("My Skills")
                    .font(SparkTypography.heading3)
                    .foregroundStyle(SparkTheme.textPrimary(colorScheme))

                SkillsRadarChart(data: radarData)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, SparkTheme.spacingMD)
    }

    // MARK: - Concept Sections

    private var conceptSections: some View {
        VStack(alignment: .leading, spacing: SparkTheme.spacingMD) {
            if !strengths.isEmpty {
                conceptRow(title: "My Strengths 💪", concepts: strengths, color: SparkTheme.teal)
            }

            if !growing.isEmpty {
                conceptRow(title: "Still Growing 🌱", concepts: growing, color: SparkTheme.practiceAmber)
            }
        }
        .padding(.horizontal, SparkTheme.spacingMD)
    }

    private func conceptRow(title: String, concepts: [ConceptProfile], color: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(SparkTypography.heading3)
                .foregroundStyle(SparkTheme.textPrimary(colorScheme))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(concepts, id: \.id) { concept in
                        Text(concept.label)
                            .font(SparkTypography.captionBold)
                            .foregroundStyle(color)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(color.opacity(0.12))
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }

    // MARK: - Assignment Timeline

    private var assignmentTimeline: some View {
        VStack(alignment: .leading, spacing: SparkTheme.spacingSM) {
            HStack {
                Text("Past Assignments")
                    .font(SparkTypography.heading3)
                    .foregroundStyle(SparkTheme.textPrimary(colorScheme))
                Spacer()
            }
            .padding(.horizontal, SparkTheme.spacingMD)

            if sessions.isEmpty {
                SparkCard {
                    Text("No assignments completed yet")
                        .font(SparkTypography.body)
                        .foregroundStyle(SparkTheme.textSecondary(colorScheme))
                        .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, SparkTheme.spacingMD)
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(sessions, id: \.id) { session in
                        sessionRow(session)
                    }
                }
                .padding(.horizontal, SparkTheme.spacingMD)
            }
        }
    }

    private func sessionRow(_ session: HomeworkSession) -> some View {
        HStack(spacing: 14) {
            Circle()
                .fill(SparkTheme.subjectColor(session.subject))
                .frame(width: 12, height: 12)

            VStack(alignment: .leading, spacing: 2) {
                Text(session.displayName)
                    .font(SparkTypography.bodyMedium)
                    .foregroundStyle(SparkTheme.textPrimary(colorScheme))
                Text(session.formattedDate)
                    .font(SparkTypography.caption)
                    .foregroundStyle(SparkTheme.gray500)
            }

            Spacer()

            if let tag = session.performanceTag {
                performanceChip(tag)
            }

            if session.adviceEntryCount > 0 {
                HStack(spacing: 3) {
                    Text("✦")
                        .font(.system(size: 10))
                    Text("\(session.adviceEntryCount)")
                        .font(SparkTypography.label)
                }
                .foregroundStyle(SparkTheme.teal)
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(SparkTheme.gray400)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: SparkTheme.radiusMD, style: .continuous)
                .fill(SparkTheme.surface(colorScheme))
        )
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
}
