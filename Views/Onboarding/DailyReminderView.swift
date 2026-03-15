import SwiftUI
import UserNotifications

struct DailyReminderView: View {
    @Binding var reminderTime: Date
    @Binding var notificationsEnabled: Bool
    let onComplete: () -> Void

    @State private var appeared = false
    @State private var permissionDenied = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 12) {
                Text("Stay consistent with\na gentle reminder.")
                    .font(SparkTypography.heading1)
                    .foregroundStyle(SparkTheme.charcoal)
                    .multilineTextAlignment(.center)

                Text("We'll nudge you once a day when it's a good time to study. Nothing more.")
                    .font(SparkTypography.bodyLarge)
                    .foregroundStyle(SparkTheme.gray600)
                    .multilineTextAlignment(.center)
            }
            .opacity(appeared ? 1 : 0)

            DatePicker(
                "Study time",
                selection: $reminderTime,
                displayedComponents: .hourAndMinute
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            .frame(maxHeight: 160)
            .opacity(appeared ? 1 : 0)

            notificationPreview
                .opacity(appeared ? 1 : 0)

            if permissionDenied {
                Text("You can enable reminders later in Settings.")
                    .font(SparkTypography.caption)
                    .foregroundStyle(SparkTheme.gray500)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            VStack(spacing: 12) {
                SparkButton(title: "Enable Reminders", style: .primary) {
                    requestNotificationPermission()
                }
                .padding(.horizontal, 48)

                Button("Maybe Later") {
                    notificationsEnabled = false
                    onComplete()
                }
                .font(SparkTypography.bodyMedium)
                .foregroundStyle(SparkTheme.gray500)
            }

            Spacer()
                .frame(height: 20)
        }
        .padding(.horizontal, SparkTheme.spacingLG)
        .onAppear {
            withAnimation(.spring(response: 0.6).delay(0.2)) {
                appeared = true
            }
        }
    }

    private var notificationPreview: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(SparkTheme.teal)
                .frame(width: 40, height: 40)
                .overlay(
                    Text("✦")
                        .font(.system(size: 20))
                        .foregroundStyle(.white)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text("Spark")
                    .font(SparkTypography.captionBold)
                    .foregroundStyle(SparkTheme.charcoal)
                Text("Let your ideas Spark! Your assignments are waiting.")
                    .font(SparkTypography.caption)
                    .foregroundStyle(SparkTheme.gray600)
                    .lineLimit(2)
            }

            Spacer()

            Text("now")
                .font(SparkTypography.label)
                .foregroundStyle(SparkTheme.gray400)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: SparkTheme.radiusMD, style: .continuous)
                .fill(.white)
                .shadow(color: Color.black.opacity(0.08), radius: 8, y: 2)
        )
        .padding(.horizontal, 16)
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async {
                if granted {
                    notificationsEnabled = true
                    onComplete()
                } else {
                    permissionDenied = true
                    notificationsEnabled = false
                }
            }
        }
    }
}
