import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Today", systemImage: "star.fill")
                }
            
            DailySummaryView()
                .tabItem {
                    Label("Summary", systemImage: "chart.bar.fill")
                }
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}
