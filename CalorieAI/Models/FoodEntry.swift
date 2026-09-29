import Foundation
import SwiftData

@Model
final class FoodEntry {
    var id: UUID = UUID()
    var createdAt: Date = Date()
    var mealType: String = MealType.other.rawValue
    
    var foodName: String
    var portionDescription: String
    var estimatedGrams: Int?
    
    var calories: Int
    var calorieMin: Int?
    var calorieMax: Int?
    
    var proteinGrams: Int?
    var carbsGrams: Int?
    var fatGrams: Int?
    
    var confidence: Double?
    
    @Attribute(.externalStorage)
    var imageData: Data?
    
    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        mealType: MealType = .other,
        foodName: String,
        portionDescription: String,
        estimatedGrams: Int? = nil,
        calories: Int,
        calorieMin: Int? = nil,
        calorieMax: Int? = nil,
        proteinGrams: Int? = nil,
        carbsGrams: Int? = nil,
        fatGrams: Int? = nil,
        confidence: Double? = nil,
        imageData: Data? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.mealType = mealType.rawValue
        self.foodName = foodName
        self.portionDescription = portionDescription
        self.estimatedGrams = estimatedGrams
        self.calories = calories
        self.calorieMin = calorieMin
        self.calorieMax = calorieMax
        self.proteinGrams = proteinGrams
        self.carbsGrams = carbsGrams
        self.fatGrams = fatGrams
        self.confidence = confidence
        self.imageData = imageData
    }
}
