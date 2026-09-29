import Foundation

struct FoodAnalysisResult: Codable {
    let foods: [FoodItem]
    let totalCalories: Int
    let totalCalorieMin: Int
    let totalCalorieMax: Int
    
    struct FoodItem: Codable {
        let name: String
        let portion: String
        let estimatedGrams: Int
        let calories: Int
        let calorieMin: Int
        let calorieMax: Int
        let proteinGrams: Int
        let carbsGrams: Int
        let fatGrams: Int
        let confidence: Double
    }
}
