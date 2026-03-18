import SwiftUI
import SwiftData

@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear(perform: applyInitialSettings)
        }
        .modelContainer(for: [
            Student.self,
            HomeworkSession.self,
            AdviceEntry.self,
            ConceptProfile.self,
            LessonPlan.self
        ])
    }

    private func applyInitialSettings() {
        do {
            let container = try ModelContainer(for: Student.self, HomeworkSession.self,
                                               AdviceEntry.self, ConceptProfile.self,
                                               LessonPlan.self)
            let context = ModelContext(container)
            let descriptor = FetchDescriptor<Student>()
            if let student = try context.fetch(descriptor).first {
                SparkTypography.useDyslexicFont = student.useDyslexicFont
                SparkTypography.textSize = student.textSize
                SpeechService.shared.setSpeed(student.preferredVoiceSpeed)
                if let key = student.claudeAPIKey, !key.isEmpty {
                    Task {
                        await ClaudeAPIClient.shared.setAPIKey(key)
                    }
                }
            }
        } catch {
            // First launch — no student yet
        }
    }
}
