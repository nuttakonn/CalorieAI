import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @FocusState private var focusedField: Field?

    @State private var weightString: String = ""
    @State private var heightString: String = ""
    @State private var ageString: String = ""
    @State private var isMale: Bool = true
    @State private var targetCaloriesString: String = ""
    @State private var useCalculatedTarget: Bool = true
    @State private var activityFactor: Double = 1.2

    // ปัญหา 2: feedback เมื่อ save สำเร็จ
    @State private var showSavedBanner: Bool = false

    enum Field: Hashable {
        case weight, height, age, targetCalories
    }

    var userProfile: UserProfile {
        if let profile = profiles.first { return profile }
        let p = UserProfile(); modelContext.insert(p); return p
    }

    var calculatedTarget: Int {
        guard let w = Double(weightString),
              let h = Double(heightString),
              let a = Int(ageString) else { return 2000 }
        let bmr = CalorieCalculator.bmr(weightKg: w, heightCm: h, age: a, isMale: isMale)
        return Int(CalorieCalculator.tdee(bmr: bmr, activityFactor: activityFactor))
    }

    var weightLossTarget: Int {
        guard let w = Double(weightString),
              let h = Double(heightString),
              let a = Int(ageString) else { return 1500 }
        let bmr = CalorieCalculator.bmr(weightKg: w, heightCm: h, age: a, isMale: isMale)
        let tdee = CalorieCalculator.tdee(bmr: bmr, activityFactor: activityFactor)
        return Int(CalorieCalculator.weightLossTarget(tdee: tdee))
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Form {
                    Section(header: Text("ข้อมูลส่วนตัว")) {
                        HStack {
                            Text("น้ำหนัก (kg)")
                            Spacer()
                            TextField("เช่น 70", text: $weightString)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .focused($focusedField, equals: .weight)
                        }
                        HStack {
                            Text("ส่วนสูง (cm)")
                            Spacer()
                            TextField("เช่น 170", text: $heightString)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .focused($focusedField, equals: .height)
                        }
                        HStack {
                            Text("อายุ")
                            Spacer()
                            TextField("เช่น 30", text: $ageString)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .focused($focusedField, equals: .age)
                        }
                        Toggle(isMale ? "เพศชาย" : "เพศหญิง", isOn: $isMale)
                    }

                    Section(header: Text("ระดับกิจกรรม")) {
                        Picker("กิจกรรม", selection: $activityFactor) {
                            Text("ไม่ค่อยขยับ (นั่งทำงาน)").tag(1.2)
                            Text("เบา (ออกกำลัง 1-3 วัน/สัปดาห์)").tag(1.375)
                            Text("ปานกลาง (3-5 วัน/สัปดาห์)").tag(1.55)
                            Text("มาก (6-7 วัน/สัปดาห์)").tag(1.725)
                            Text("หนักมาก (งานหนัก+ออกกำลัง)").tag(1.9)
                        }
                        .pickerStyle(.menu)
                    }

                    Section(header: Text("เป้าหมายแคลอรี่")) {
                        Toggle("คำนวณอัตโนมัติ (TDEE)", isOn: $useCalculatedTarget)

                        if useCalculatedTarget {
                            HStack {
                                Text("TDEE ของคุณ")
                                Spacer()
                                Text("\(calculatedTarget) kcal")
                                    .foregroundColor(.secondary)
                            }
                            HStack {
                                Text("🎯 เป้าลดน้ำหนัก (-500 kcal)")
                                Spacer()
                                Text("\(weightLossTarget) kcal")
                                    .foregroundColor(.green)
                                    .fontWeight(.semibold)
                            }
                        } else {
                            HStack {
                                Text("กำหนดเอง")
                                Spacer()
                                TextField("kcal", text: $targetCaloriesString)
                                    .keyboardType(.numberPad)
                                    .multilineTextAlignment(.trailing)
                                    .focused($focusedField, equals: .targetCalories)
                            }
                        }
                    }

                    // ปัญหา 2: ปุ่ม save ชัดเจน + มีสี
                    Section {
                        Button(action: saveProfile) {
                            HStack {
                                Spacer()
                                Image(systemName: "checkmark.circle.fill")
                                Text("บันทึกการตั้งค่า")
                                    .fontWeight(.semibold)
                                Spacer()
                            }
                        }
                        .foregroundColor(.white)
                        .listRowBackground(Color.blue)
                    }
                }
                // ปัญหา 3: Done button บน keyboard ตัวเลข
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("เสร็จ") { focusedField = nil }
                            .fontWeight(.semibold)
                    }
                }
                .navigationTitle("ตั้งค่า")
                .onAppear { loadProfile() }

                // ปัญหา 2: Banner แจ้งเตือนบันทึกสำเร็จ
                if showSavedBanner {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("บันทึกสำเร็จแล้ว!")
                            .fontWeight(.semibold)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(.regularMaterial)
                    .clipShape(Capsule())
                    .shadow(radius: 6)
                    .padding(.top, 10)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(1)
                }
            }
        }
    }

    private func loadProfile() {
        let p = userProfile
        weightString = String(p.weightKg)
        heightString = String(p.heightCm)
        ageString = String(p.age)
        isMale = p.isMale
        targetCaloriesString = String(p.targetCalories)
        useCalculatedTarget = p.useCalculatedTarget
        activityFactor = p.activityFactor
    }

    private func saveProfile() {
        focusedField = nil  // ปิด keyboard ก่อน save
        let p = userProfile
        if let w = Double(weightString) { p.weightKg = w }
        if let h = Double(heightString) { p.heightCm = h }
        if let a = Int(ageString)       { p.age = a }
        p.isMale = isMale
        p.useCalculatedTarget = useCalculatedTarget
        p.activityFactor = activityFactor

        if useCalculatedTarget {
            p.targetCalories = calculatedTarget
        } else if let t = Int(targetCaloriesString) {
            p.targetCalories = t
        }

        try? modelContext.save()

        // ปัญหา 2: แสดง banner แจ้งเตือน
        withAnimation(.spring()) { showSavedBanner = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation(.easeOut) { showSavedBanner = false }
        }
    }
}
