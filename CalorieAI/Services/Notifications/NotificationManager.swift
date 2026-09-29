import Foundation
import UserNotifications

final class NotificationManager: Sendable {
    static let shared = NotificationManager()
    
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if granted {
                self.scheduleDailyReminder()
            }
        }
    }
    
    private func scheduleDailyReminder() {
        let content = UNMutableNotificationContent()
        content.title = "Daily calorie summary"
        content.body = "Tap to view your summary for today."
        content.sound = .default
        
        var dateComponents = DateComponents()
        dateComponents.hour = 20
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let request = UNNotificationRequest(identifier: "dailyReminder", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error)")
            }
        }
    }
}
