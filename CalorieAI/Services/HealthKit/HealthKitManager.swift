import Foundation
import HealthKit

final class HealthKitManager: Sendable {
    static let shared = HealthKitManager()
    private let healthStore = HKHealthStore()
    
    var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }
    
    func requestAuthorization() async throws {
        guard isAvailable else { return }
        
        let stepCount = HKQuantityType(.stepCount)
        let activeEnergy = HKQuantityType(.activeEnergyBurned)
        let bodyMass = HKQuantityType(.bodyMass)
        
        let typesToRead: Set = [stepCount, activeEnergy, bodyMass]
        
        try await healthStore.requestAuthorization(toShare: [], read: typesToRead)
    }
    
    func fetchTodaySteps() async throws -> Int {
        guard isAvailable else { return 0 }
        let type = HKQuantityType(.stepCount)
        let predicate = HKQuery.predicateForSamples(withStart: Calendar.current.startOfDay(for: Date()), end: Date(), options: .strictStartDate)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let sum = result?.sumQuantity() else {
                    continuation.resume(returning: 0)
                    return
                }
                continuation.resume(returning: Int(sum.doubleValue(for: .count())))
            }
            healthStore.execute(query)
        }
    }
    
    func fetchTodayActiveEnergy() async throws -> Int {
        guard isAvailable else { return 0 }
        let type = HKQuantityType(.activeEnergyBurned)
        let predicate = HKQuery.predicateForSamples(withStart: Calendar.current.startOfDay(for: Date()), end: Date(), options: .strictStartDate)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let sum = result?.sumQuantity() else {
                    continuation.resume(returning: 0)
                    return
                }
                continuation.resume(returning: Int(sum.doubleValue(for: .kilocalorie())))
            }
            healthStore.execute(query)
        }
    }
    
    func fetchLatestWeight() async throws -> Double {
        guard isAvailable else { return 0.0 }
        let type = HKQuantityType(.bodyMass)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: 0.0)
                    return
                }
                continuation.resume(returning: sample.quantity.doubleValue(for: .gramUnit(with: .kilo)))
            }
            healthStore.execute(query)
        }
    }
    
    func fetch7DayWeightHistory() async throws -> [(date: Date, weight: Double)] {
        guard isAvailable else { return [] }
        let type = HKQuantityType(.bodyMass)
        let calendar = Calendar.current
        let endDate = Date()
        guard let startDate = calendar.date(byAdding: .day, value: -7, to: endDate) else { return [] }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                let results = samples?.compactMap { sample -> (Date, Double)? in
                    guard let quantitySample = sample as? HKQuantitySample else { return nil }
                    return (quantitySample.startDate, quantitySample.quantity.doubleValue(for: .gramUnit(with: .kilo)))
                } ?? []
                continuation.resume(returning: results)
            }
            healthStore.execute(query)
        }
    }
}
