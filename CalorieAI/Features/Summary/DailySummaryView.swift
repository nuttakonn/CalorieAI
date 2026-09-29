import SwiftUI
import SwiftData
import Charts

struct DailySummaryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) var scenePhase
    @Query(sort: \FoodEntry.createdAt, order: .reverse) private var foodEntries: [FoodEntry]
    @Query private var profiles: [UserProfile]

    @State private var viewModel = DashboardViewModel()

    var userProfile: UserProfile {
        if let profile = profiles.first { return profile }
        let p = UserProfile(); modelContext.insert(p); return p
    }

    var todayEntries: [FoodEntry] {
        let today = Calendar.current.startOfDay(for: Date())
        return foodEntries.filter { Calendar.current.isDate($0.createdAt, inSameDayAs: today) }
    }

    var consumed: Int { todayEntries.reduce(0) { $0 + $1.calories } }
    var target: Int   { userProfile.targetCalories }
    var remaining: Int { CalorieCalculator.remaining(target: target, consumed: consumed) }
    var isOver: Bool  { CalorieCalculator.isOverTarget(target: target, consumed: consumed) }
    var overAmount: Int { CalorieCalculator.overAmount(target: target, consumed: consumed) }

    var totalProtein: Int { todayEntries.compactMap { $0.proteinGrams }.reduce(0, +) }
    var totalCarbs: Int   { todayEntries.compactMap { $0.carbsGrams }.reduce(0, +) }
    var totalFat: Int     { todayEntries.compactMap { $0.fatGrams }.reduce(0, +) }

    // MARK: - BMR / TDEE
    var bmr: Double {
        CalorieCalculator.bmr(
            weightKg: userProfile.weightKg,
            heightCm: userProfile.heightCm,
            age: userProfile.age,
            isMale: userProfile.isMale
        )
    }
    var tdee: Double { CalorieCalculator.tdee(bmr: bmr, activityFactor: userProfile.activityFactor) }
    var weightLossTarget: Double { CalorieCalculator.weightLossTarget(tdee: tdee) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    calorieSummarySection
                    macroSection
                    bmrTdeeSection
                    activitySummarySection
                    weightChartSection
                }
                .padding()
            }
            .navigationTitle("สรุปวันนี้")
            .onAppear {
                viewModel.isMockMode = false
                viewModel.refreshHealthData()
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active { viewModel.refreshHealthData() }
            }
        }
    }

    // MARK: - Calorie Summary
    private var calorieSummarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("แคลอรี่วันนี้")
                .font(.headline)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("กินแล้ว")
                        .font(.caption).foregroundColor(.secondary)
                    Text("\(consumed) kcal")
                        .font(.title2.bold())
                }
                Spacer()
                VStack(alignment: .center, spacing: 4) {
                    Text("เป้าหมาย")
                        .font(.caption).foregroundColor(.secondary)
                    Text("\(target) kcal")
                        .font(.title2.bold())
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(isOver ? "เกิน" : "เหลือ")
                        .font(.caption)
                        .foregroundColor(isOver ? .red : .secondary)
                    Text(isOver ? "\(overAmount) kcal" : "\(remaining) kcal")
                        .font(.title2.bold())
                        .foregroundColor(isOver ? .red : .green)
                }
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(.systemGray5))
                        .frame(height: 12)
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isOver ? Color.red : Color.green)
                        .frame(width: geo.size.width * min(Double(consumed) / Double(max(target, 1)), 1.0), height: 12)
                        .animation(.easeOut(duration: 0.4), value: consumed)
                }
            }
            .frame(height: 12)

            if isOver {
                Label("เกินเป้าหมาย \(overAmount) kcal วันนี้", systemImage: "exclamationmark.triangle.fill")
                    .font(.caption.bold())
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }

    // MARK: - Macros
    private var macroSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("สารอาหาร")
                .font(.headline)
            HStack(spacing: 0) {
                macroCell(title: "Protein", value: totalProtein, unit: "g", color: .blue)
                Divider().frame(height: 50)
                macroCell(title: "Carbs",   value: totalCarbs,   unit: "g", color: .orange)
                Divider().frame(height: 50)
                macroCell(title: "Fat",     value: totalFat,     unit: "g", color: .purple)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }

    private func macroCell(title: String, value: Int, unit: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text("\(value) \(unit)")
                .font(.title3.bold())
                .foregroundColor(color)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - BMR / TDEE
    private var bmrTdeeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ค่าพลังงานฐาน (BMR/TDEE)")
                .font(.headline)

            infoRow(label: "BMR (พลังงานฐาน)", value: String(format: "%.0f kcal/วัน", bmr), icon: "bed.double.fill", color: .teal)
            Divider()
            infoRow(label: "TDEE (พลังงานทั้งวัน)", value: String(format: "%.0f kcal/วัน", tdee), icon: "figure.run", color: .blue)
            Divider()
            infoRow(label: "เป้าลดน้ำหนัก (-500 kcal)", value: String(format: "%.0f kcal/วัน", weightLossTarget), icon: "arrow.down.circle.fill", color: .green)
            Divider()

            HStack {
                Image(systemName: "info.circle")
                    .foregroundColor(.secondary)
                Text("ลดน้ำหนักประมาณ 0.5 kg/สัปดาห์ เมื่อกินต่ำกว่า TDEE 500 kcal/วัน")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }

    private func infoRow(label: String, value: String, icon: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
            Text(label)
                .font(.subheadline)
            Spacer()
            Text(value)
                .font(.subheadline.bold())
        }
    }

    // MARK: - Activity
    private var activitySummarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("กิจกรรม")
                .font(.headline)
            HStack(spacing: 0) {
                activityCell(icon: "figure.walk", title: "ก้าว", value: "\(viewModel.steps.formatted())", color: .teal)
                Divider().frame(height: 50)
                activityCell(icon: "flame.fill", title: "Active Energy", value: "\(viewModel.activeEnergy) kcal", color: .orange)
                Divider().frame(height: 50)
                activityCell(icon: "scalemass.fill", title: "น้ำหนัก", value: String(format: "%.1f kg", viewModel.weight), color: .indigo)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }

    private func activityCell(icon: String, title: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon).foregroundColor(color).font(.title3)
            Text(value).font(.subheadline.bold())
            Text(title).font(.caption).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Weight Chart
    private var weightChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("น้ำหนัก 7 วัน")
                .font(.headline)

            if viewModel.weightHistory.count < 2 {
                VStack(spacing: 8) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("ยังไม่มีข้อมูลเพียงพอ\nบันทึกน้ำหนักใน Apple Health ต่อไป")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else {
                Chart(viewModel.weightHistory) { item in
                    LineMark(
                        x: .value("วัน", item.date, unit: .day),
                        y: .value("น้ำหนัก", item.weight)
                    )
                    .foregroundStyle(Color.indigo)
                    PointMark(
                        x: .value("วัน", item.date, unit: .day),
                        y: .value("น้ำหนัก", item.weight)
                    )
                    .foregroundStyle(Color.indigo)
                }
                .frame(height: 180)
                .chartYScale(domain: .automatic(includesZero: false))
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
}
