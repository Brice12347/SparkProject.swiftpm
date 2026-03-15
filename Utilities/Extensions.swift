import SwiftUI

// MARK: - View Accessibility Helpers

extension View {
    func sparkAccessibility(label: String, hint: String? = nil) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
    }

    func sparkTapTarget() -> some View {
        self.frame(minWidth: 48, minHeight: 48)
    }
}

// MARK: - Conditional Modifier

extension View {
    @ViewBuilder
    func `if`<Transform: View>(_ condition: Bool, transform: (Self) -> Transform) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

// MARK: - Haptic Helpers

enum SparkHaptic {
    static func light() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func medium() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    static func heavy() {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
    }

    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func adviceLogged() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func sessionComplete() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    static func lessonComplete() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func streakMilestone() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}

// MARK: - Date Helpers

extension Date {
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    var isYesterday: Bool {
        Calendar.current.isDateInYesterday(self)
    }

    var relativeDescription: String {
        if isToday { return "Today" }
        if isYesterday { return "Yesterday" }
        return formatted(date: .abbreviated, time: .omitted)
    }
}
