import Foundation
import SwiftData
import SwiftUI

@MainActor
@Observable
class DashboardViewModel {
    var steps: Int = 0
    var activeEnergy: Int = 0
    var weight: Double = 0.0
    
    struct WeightDataPoint: Identifiable {
        let id = UUID()
        let date: Date
        let weight: Double
    }
    var weightHistory: [WeightDataPoint] = []
    
    // For mock mode
    var isMockMode: Bool = false
    private var isRefreshing: Bool = false  // ป้องกัน query ซ้อน

    func refreshHealthData() {
        guard !isRefreshing else { return }  // ปัญหา 5: ถ้า query อยู่แล้วไม่ query ซ้ำ
        if isMockMode {
            steps = 8240
            activeEnergy = 430
            weight = 67.0
            let calendar = Calendar.current
            let today = Date()
            weightHistory = (0..<7).reversed().map {
                let d = calendar.date(byAdding: .day, value: -$0, to: today)!
                return WeightDataPoint(date: d, weight: 67.0 + Double.random(in: -0.5...0.5))
            }
        } else {
            isRefreshing = true
            Task.detached(priority: .background) { [weak self] in
                guard let self else { return }
                do {
                    try await HealthKitManager.shared.requestAuthorization()
                    async let s = HealthKitManager.shared.fetchTodaySteps()
                    async let e = HealthKitManager.shared.fetchTodayActiveEnergy()
                    async let w = HealthKitManager.shared.fetchLatestWeight()
                    async let h = HealthKitManager.shared.fetch7DayWeightHistory()
                    let (fetchedSteps, fetchedEnergy, fetchedWeight, history) = try await (s, e, w, h)
                    await MainActor.run {
                        self.steps = fetchedSteps
                        self.activeEnergy = fetchedEnergy
                        if fetchedWeight > 0 { self.weight = fetchedWeight }
                        self.weightHistory = history.map { WeightDataPoint(date: $0.date, weight: $0.weight) }
                        self.isRefreshing = false
                    }
                } catch {
                    await MainActor.run { self.isRefreshing = false }
                    // Code=11 = ไม่มีข้อมูล (ปกติ), ไม่ต้อง print
                    let nsError = error as NSError
                    if nsError.code != 11 { print("HealthKit Error: \(error)") }
                }
            }
        }
    }

    
    func todayConsumedCalories(entries: [FoodEntry]) -> Int {
        let today = Calendar.current.startOfDay(for: Date())
        return entries
            .filter { Calendar.current.isDate($0.createdAt, inSameDayAs: today) }
            .reduce(0) { $0 + $1.calories }
    }
    
    func remainingCalories(entries: [FoodEntry], target: Int) -> Int {
        let consumed = todayConsumedCalories(entries: entries)
        return max(0, target - consumed)
    }
}
