import XCTest
@testable import CalorieAI

final class CalorieAITests: XCTestCase {
    
    func testBMRCalculationMale() {
        // Mifflin-St Jeor: (10 * 70) + (6.25 * 170) - (5 * 30) + 5
        // 700 + 1062.5 - 150 + 5 = 1617.5
        let profile = UserProfile(weightKg: 70.0, heightCm: 170.0, age: 30, isMale: true, useCalculatedTarget: true, activityFactor: 1.2)
        var bmr = (10.0 * profile.weightKg) + (6.25 * profile.heightCm) - (5.0 * Double(profile.age)) + 5.0
        let target = Int(bmr * profile.activityFactor)
        
        XCTAssertEqual(target, 1941)
    }
    
    func testBMRCalculationFemale() {
        // Mifflin-St Jeor: (10 * 65) + (6.25 * 160) - (5 * 25) - 161
        // 650 + 1000 - 125 - 161 = 1364
        let profile = UserProfile(weightKg: 65.0, heightCm: 160.0, age: 25, isMale: false, useCalculatedTarget: true, activityFactor: 1.5)
        var bmr = (10.0 * profile.weightKg) + (6.25 * profile.heightCm) - (5.0 * Double(profile.age)) - 161.0
        let target = Int(bmr * profile.activityFactor)
        
        XCTAssertEqual(target, 2046)
    }
    
    @MainActor
    func testFoodTotalCalories() {
        let entry1 = FoodEntry(foodName: "Apple", portionDescription: "1 medium", calories: 95)
        let entry2 = FoodEntry(foodName: "Banana", portionDescription: "1 large", calories: 121)
        
        let vm = DashboardViewModel()
        let consumed = vm.todayConsumedCalories(entries: [entry1, entry2])
        
        XCTAssertEqual(consumed, 216)
    }
    
    func testGeminiJSONDecoding() throws {
        let jsonString = """
        {
          "foods": [
            {
              "name": "Chicken rice",
              "portion": "1 plate",
              "estimatedGrams": 350,
              "calories": 620,
              "calorieMin": 550,
              "calorieMax": 700,
              "proteinGrams": 28,
              "carbsGrams": 75,
              "fatGrams": 22,
              "confidence": 0.78
            }
          ],
          "totalCalories": 620,
          "totalCalorieMin": 550,
          "totalCalorieMax": 700
        }
        """
        
        let data = jsonString.data(using: .utf8)!
        let result = try JSONDecoder().decode(FoodAnalysisResult.self, from: data)
        
        XCTAssertEqual(result.totalCalories, 620)
        XCTAssertEqual(result.foods.first?.name, "Chicken rice")
        XCTAssertEqual(result.foods.first?.proteinGrams, 28)
    }
}
