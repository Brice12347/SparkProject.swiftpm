import UserNotifications

final class NotificationService: Sendable {
    static let shared = NotificationService()

    func scheduleDailyReminder(at time: Date) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["daily_reminder"])

        let content = UNMutableNotificationContent()
        content.title = "Spark"
        content.body = "Let your ideas Spark! Your assignments are waiting."
        content.sound = .default

        let components = Calendar.current.dateComponents([.hour, .minute], from: time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let request = UNNotificationRequest(identifier: "daily_reminder", content: content, trigger: trigger)
        center.add(request)
    }

    func scheduleStreakAtRisk() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["streak_at_risk"])

        let content = UNMutableNotificationContent()
        content.title = "Streak at Risk!"
        content.body = "Don't break your streak! 5 minutes today keeps it alive. 🔥"
        content.sound = .default

        var components = DateComponents()
        components.hour = 22
        components.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let request = UNNotificationRequest(identifier: "streak_at_risk", content: content, trigger: trigger)
        center.add(request)
    }

    func scheduleNewLessonAvailable(conceptLabel: String) {
        let content = UNMutableNotificationContent()
        content.title = "New Lesson Ready"
        content.body = "Spark built you a new lesson on \(conceptLabel). Ready when you are."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(identifier: "lesson_\(UUID().uuidString)", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func scheduleStreakMilestone(days: Int, studentName: String) {
        let content = UNMutableNotificationContent()
        content.title = "🔥 \(days)-day streak!"
        content.body = "You're on fire, \(studentName)."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
        let request = UNNotificationRequest(identifier: "streak_milestone", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func removeAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
