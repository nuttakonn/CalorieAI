import SwiftUI
import SwiftData

struct FoodAnalysisView: View {
    let image: UIImage
    var onSaved: (() -> Void)? = nil
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var isLoading = true
    @State private var errorMessage: String? = nil
    
    @State private var foodName: String = ""
    @State private var portionDescription: String = ""
    @State private var caloriesString: String = ""
    @State private var calorieRangeString: String = ""
    @State private var proteinString: String = ""
    @State private var carbsString: String = ""
    @State private var fatString: String = ""
    @State private var confidenceString: String = ""
    @State private var selectedMealType: MealType = MealType.guessMealType()
    
    @State private var originalImageData: Data?
    
    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("กำลังวิเคราะห์อาหาร...")
                            .font(.headline)
                        Text("กำลังระบุส่วนผสม\nกำลังประมาณขนาดส่วน\nกำลังประมาณแคลอรี่")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                        Text("อาจใช้เวลา 10-30 วินาที")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else if let error = errorMessage {
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.red)
                        Text("Unable to analyze this image.")
                            .font(.headline)
                        Text(error)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                        
                        Button("Enter Manually") {
                            // Instead of full navigation, we could dismiss or clear state
                            dismiss()
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        
                        Button("Try Again") {
                            analyzeImage()
                        }
                    }
                    .padding()
                } else {
                    Form {
                        Section(header: Text("AI Analysis")) {
                            TextField("Food name", text: $foodName)
                            TextField("Portion", text: $portionDescription)
                            Picker("Meal Type", selection: $selectedMealType) {
                                ForEach(MealType.allCases, id: \.self) { type in
                                    Text(type.rawValue).tag(type)
                                }
                            }
                            .pickerStyle(.menu)
                        }
                        
                        Section(header: Text("Nutrition Estimates")) {
                            HStack {
                                Text("Calories")
                                Spacer()
                                TextField("kcal", text: $caloriesString)
                                    .keyboardType(.numberPad)
                                    .multilineTextAlignment(.trailing)
                            }
                            
                            if !calorieRangeString.isEmpty {
                                HStack {
                                    Text("Estimated range")
                                    Spacer()
                                    Text(calorieRangeString)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            HStack {
                                Text("Protein (g)")
                                Spacer()
                                TextField("g", text: $proteinString)
                                    .keyboardType(.numberPad)
                                    .multilineTextAlignment(.trailing)
                            }
                            
                            HStack {
                                Text("Carbs (g)")
                                Spacer()
                                TextField("g", text: $carbsString)
                                    .keyboardType(.numberPad)
                                    .multilineTextAlignment(.trailing)
                            }
                            
                            HStack {
                                Text("Fat (g)")
                                Spacer()
                                TextField("g", text: $fatString)
                                    .keyboardType(.numberPad)
                                    .multilineTextAlignment(.trailing)
                            }
                            
                            if !confidenceString.isEmpty {
                                HStack {
                                    Text("Confidence")
                                    Spacer()
                                    Text(confidenceString)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Confirm Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if !isLoading && errorMessage == nil {
                        Button("Save Food") { saveFood() }
                            .disabled(foodName.isEmpty || caloriesString.isEmpty)
                    }
                }
            }
            .onAppear {
                analyzeImage()
            }
        }
    }
    
    private func analyzeImage() {
        isLoading = true
        errorMessage = nil
        
        Task {
            guard let data = ImageCompressor.compress(image: image, maxMB: 1.0) else {
                await MainActor.run {
                    self.errorMessage = "Failed to compress image."
                    self.isLoading = false
                }
                return
            }
            
            originalImageData = data
            
            let service = OpenRouterService.default
            do {
                let result = try await service.analyzeFood(image: data)
                await MainActor.run {
                    populateFields(with: result)
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Please check your internet connection or enter the food manually.\n\(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    private func populateFields(with result: FoodAnalysisResult) {
        if let food = result.foods.first {
            foodName = food.name
            portionDescription = food.portion
            caloriesString = "\(food.calories)"
            calorieRangeString = "\(food.calorieMin) - \(food.calorieMax) kcal"
            proteinString = "\(food.proteinGrams)"
            carbsString = "\(food.carbsGrams)"
            fatString = "\(food.fatGrams)"
            confidenceString = "\(Int(food.confidence * 100))%"
        } else {
            caloriesString = "\(result.totalCalories)"
            calorieRangeString = "\(result.totalCalorieMin) - \(result.totalCalorieMax) kcal"
        }
    }
    
    private func saveFood() {
        guard let calories = Int(caloriesString.trimmingCharacters(in: .whitespaces)) else { return }

        // Parse calorieRange "550 - 700 kcal"
        let rangeParts = calorieRangeString
            .replacingOccurrences(of: " kcal", with: "")
            .components(separatedBy: " - ")
        let calorieMin = Int(rangeParts.first?.trimmingCharacters(in: .whitespaces) ?? "")
        let calorieMax = Int(rangeParts.last?.trimmingCharacters(in: .whitespaces) ?? "")

        // Parse macros – default to 0 if empty so we always save something
        let protein = Int(proteinString.trimmingCharacters(in: .whitespaces)) ?? 0
        let carbs   = Int(carbsString.trimmingCharacters(in: .whitespaces)) ?? 0
        let fat     = Int(fatString.trimmingCharacters(in: .whitespaces)) ?? 0

        let confidenceRaw = confidenceString.replacingOccurrences(of: "%", with: "").trimmingCharacters(in: .whitespaces)
        let confidence = (Double(confidenceRaw) ?? 0) / 100.0

        let entry = FoodEntry(
            mealType: selectedMealType,
            foodName: foodName,
            portionDescription: portionDescription,
            calories: calories,
            calorieMin: calorieMin,
            calorieMax: calorieMax,
            proteinGrams: protein,
            carbsGrams: carbs,
            fatGrams: fat,
            confidence: confidence,
            imageData: nil  // ไม่เก็บรูปไว้ประหยัดพื้นที่ (รูปใช้แค่ส่ง AI เท่านั้น)
        )

        modelContext.insert(entry)
        dismiss()
        onSaved?()
    }
}
