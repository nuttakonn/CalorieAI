import Foundation

enum MealType: String, Codable, CaseIterable {
    case breakfast = "Breakfast"
    case lunch = "Lunch"
    case dinner = "Dinner"
    case snack = "Snack"
    case other = "Other"
    
    static func guessMealType(for date: Date = Date()) -> MealType {
        let hour = Calendar.current.component(.hour, from: date)
        switch hour {
        case 5..<11:
            return .breakfast
        case 11..<15:
            return .lunch
        case 17..<22:
            return .dinner
        default:
            return .snack
        }
    }
}
