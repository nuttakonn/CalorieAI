import SwiftUI
import SwiftData

struct ManualFoodView: View {
    var onSaved: (() -> Void)? = nil
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: Field?

    // ปัญหา 1: ใช้ @State ปกติแต่เพิ่ม keyboard Done button ป้องกัน data loss
    @State private var foodName: String = ""
    @State private var portionDescription: String = "1 serving"
    @State private var caloriesString: String = ""
    @State private var proteinString: String = ""
    @State private var carbsString: String = ""
    @State private var fatString: String = ""
    @State private var selectedMealType: MealType = MealType.guessMealType()

    enum Field: Hashable {
        case foodName, portion, calories, protein, carbs, fat
    }

    var body: some View {
        Form {
            Section(header: Text("รายละเอียดอาหาร")) {
                TextField("ชื่ออาหาร", text: $foodName)
                    .focused($focusedField, equals: .foodName)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .portion }

                TextField("ปริมาณ (เช่น 1 จาน)", text: $portionDescription)
                    .focused($focusedField, equals: .portion)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .calories }

                Picker("มื้ออาหาร", selection: $selectedMealType) {
                    ForEach(MealType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.menu)
            }

            Section(header: Text("แคลอรี่ (จำเป็น)")) {
                TextField("แคลอรี่ (kcal)", text: $caloriesString)
                    .keyboardType(.numberPad)
                    .focused($focusedField, equals: .calories)
            }

            Section(header: Text("สารอาหาร (ไม่บังคับ - ระบบใส่ 0 ให้ถ้าไม่กรอก)")) {
                TextField("Protein (g)", text: $proteinString)
                    .keyboardType(.numberPad)
                    .focused($focusedField, equals: .protein)

                TextField("Carbs (g)", text: $carbsString)
                    .keyboardType(.numberPad)
                    .focused($focusedField, equals: .carbs)

                TextField("Fat (g)", text: $fatString)
                    .keyboardType(.numberPad)
                    .focused($focusedField, equals: .fat)
            }
        }
        .navigationTitle("บันทึกอาหาร")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // Done button on number keyboard
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("เสร็จ") { focusedField = nil }
                    .fontWeight(.semibold)
            }
            // Save button in nav bar
            ToolbarItem(placement: .confirmationAction) {
                Button("บันทึก") { saveFood() }
                    .disabled(foodName.isEmpty || caloriesString.isEmpty)
                    .fontWeight(.semibold)
            }
        }
    }

    private func saveFood() {
        guard let calories = Int(caloriesString.trimmingCharacters(in: .whitespaces)) else { return }
        // ปัญหา 4: ไม่รู้แมคโคร → ใส่ 0 ให้อัตโนมัติ
        let protein = Int(proteinString.trimmingCharacters(in: .whitespaces)) ?? 0
        let carbs   = Int(carbsString.trimmingCharacters(in: .whitespaces)) ?? 0
        let fat     = Int(fatString.trimmingCharacters(in: .whitespaces)) ?? 0

        let entry = FoodEntry(
            mealType: selectedMealType,
            foodName: foodName,
            portionDescription: portionDescription,
            calories: calories,
            proteinGrams: protein,
            carbsGrams: carbs,
            fatGrams: fat
        )

        modelContext.insert(entry)
        dismiss()
        onSaved?()
    }
}
