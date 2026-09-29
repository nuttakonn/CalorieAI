import Foundation

struct CalorieCalculator {

    // MARK: - BMR (Mifflin-St Jeor)
    static func bmr(weightKg: Double, heightCm: Double, age: Int, isMale: Bool) -> Double {
        let base = (10 * weightKg) + (6.25 * heightCm) - (5 * Double(age))
        return isMale ? base + 5 : base - 161
    }

    // MARK: - TDEE
    static func tdee(bmr: Double, activityFactor: Double) -> Double {
        return bmr * activityFactor
    }

    // MARK: - Calorie target for weight loss (deficit 500 kcal/day = ~0.5kg/week)
    static func weightLossTarget(tdee: Double, deficitKcal: Double = 500) -> Double {
        return max(tdee - deficitKcal, 1200)
    }

    // MARK: - Remaining calories
    static func remaining(target: Int, consumed: Int) -> Int {
        return max(0, target - consumed)
    }

    // MARK: - Is over target
    static func isOverTarget(target: Int, consumed: Int) -> Bool {
        return consumed > target
    }

    // MARK: - Over amount
    static func overAmount(target: Int, consumed: Int) -> Int {
        return max(0, consumed - target)
    }

    // MARK: - Activity factor display name
    static func activityLabel(factor: Double) -> String {
        switch factor {
        case ..<1.3:  return "Sedentary (little/no exercise)"
        case ..<1.45: return "Light (1-3 days/week)"
        case ..<1.6:  return "Moderate (3-5 days/week)"
        case ..<1.75: return "Active (6-7 days/week)"
        default:      return "Very Active (hard exercise)"
        }
    }
}
