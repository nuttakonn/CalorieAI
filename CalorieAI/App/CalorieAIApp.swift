import SwiftUI
import SwiftData

@main
struct CalorieAIApp: App {
    init() {
        NotificationManager.shared.requestPermission()
    }
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(for: [FoodEntry.self, UserProfile.self])
    }
}
