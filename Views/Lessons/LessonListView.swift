import SwiftUI
import SwiftData

struct LessonListView: View {
    let student: Student
    @Environment(\.colorScheme) private var colorScheme
    @Query(sort: \LessonPlan.generatedAt, order: .reverse) private var allPlans: [LessonPlan]

    private var plans: [LessonPlan] {
        allPlans.filter { $0.studentId == student.id }
    }

    private var activePlans: [LessonPlan] {
        plans.filter { !$0.isComplete }
    }

    private var completedPlans: [LessonPlan] {
        plans.filter { $0.isComplete }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: SparkTheme.spacingLG) {
                Text("Lessons")
                    .font(SparkTypography.heading1)
                    .foregroundStyle(SparkTheme.textPrimary(colorScheme))
                    .padding(.top, 8)

                if plans.isEmpty {
                    emptyState
                } else {
                    if !activePlans.isEmpty {
                        sectionHeader("In Progress")
                        ForEach(activePlans, id: \.id) { plan in
                            NavigationLink {
                                LessonSessionView(plan: plan, student: student)
                            } label: {
                                lessonCard(plan)
                            }
                        }
                    }

                    if !completedPlans.isEmpty {
                        sectionHeader("Completed")
                        ForEach(completedPlans, id: \.id) { plan in
                            lessonCard(plan, completed: true)
                        }
                    }
                }

                Spacer(minLength: 20)
            }
            .padding(.horizontal, SparkTheme.spacingMD)
        }
        .background(SparkTheme.background(colorScheme).ignoresSafeArea())
        .navigationBarHidden(true)
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(SparkTypography.heading3)
            .foregroundStyle(SparkTheme.textSecondary(colorScheme))
    }

    private var emptyState: some View {
        SparkCard {
            VStack(spacing: 16) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(SparkTheme.teal)

                Text("No lessons yet")
                    .font(SparkTypography.heading2)
                    .foregroundStyle(SparkTheme.textPrimary(colorScheme))

                Text("As you complete homework sessions, Spark will notice concepts you need more help with and create personalized lessons just for you.")
                    .font(SparkTypography.body)
                    .foregroundStyle(SparkTheme.textSecondary(colorScheme))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
        }
    }

    private func lessonCard(_ plan: LessonPlan, completed: Bool = false) -> some View {
        SparkCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    Circle()
                        .fill(SparkTheme.subjectColor(plan.subject))
                        .frame(width: 12, height: 12)

                    Text(plan.subject.displayName)
                        .font(SparkTypography.label)
                        .foregroundStyle(SparkTheme.textSecondary(colorScheme))

                    Spacer()

                    if completed {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 14))
                            Text("Complete")
                                .font(SparkTypography.label)
                        }
                        .foregroundStyle(SparkTheme.strengthGreen)
                    }
                }

                Text(plan.conceptLabel)
                    .font(SparkTypography.heading3)
                    .foregroundStyle(SparkTheme.textPrimary(colorScheme))

                // Progress bar
                if !completed {
                    VStack(alignment: .leading, spacing: 6) {
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(SparkTheme.gray200)
                                    .frame(height: 8)

                                RoundedRectangle(cornerRadius: 4)
                                    .fill(SparkTheme.teal)
                                    .frame(width: geo.size.width * plan.progress, height: 8)
                            }
                        }
                        .frame(height: 8)

                        HStack {
                            Text("Step \(plan.currentStepIndex + 1) of \(plan.totalSteps)")
                                .font(SparkTypography.label)
                                .foregroundStyle(SparkTheme.gray500)

                            Spacer()

                            Text("Continue →")
                                .font(SparkTypography.captionBold)
                                .foregroundStyle(SparkTheme.teal)
                        }
                    }
                }
            }
        }
    }
}
