import Foundation
import SwiftData

@Model
final class UserProfile {
    var weightKg: Double
    var heightCm: Double
    var age: Int
    var isMale: Bool
    
    // User can manually override this
    var targetCalories: Int
    var useCalculatedTarget: Bool
    
    var activityFactor: Double
    
    init(
        weightKg: Double = 70.0,
        heightCm: Double = 170.0,
        age: Int = 30,
        isMale: Bool = true,
        targetCalories: Int = 2000,
        useCalculatedTarget: Bool = true,
        activityFactor: Double = 1.2
    ) {
        self.weightKg = weightKg
        self.heightCm = heightCm
        self.age = age
        self.isMale = isMale
        self.targetCalories = targetCalories
        self.useCalculatedTarget = useCalculatedTarget
        self.activityFactor = activityFactor
    }
}
