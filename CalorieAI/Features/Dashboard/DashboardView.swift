import SwiftUI
import SwiftData
import Charts

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) var scenePhase
    @Query(sort: \FoodEntry.createdAt, order: .reverse) private var foodEntries: [FoodEntry]
    @Query private var profiles: [UserProfile]

    @State private var viewModel = DashboardViewModel()
    @State private var showingAddFood = false

    var userProfile: UserProfile {
        if let profile = profiles.first { return profile }
        let p = UserProfile(); modelContext.insert(p); return p
    }

    var todayEntries: [FoodEntry] {
        let today = Calendar.current.startOfDay(for: Date())
        return foodEntries.filter { Calendar.current.isDate($0.createdAt, inSameDayAs: today) }
    }

    var consumed: Int { todayEntries.reduce(0) { $0 + $1.calories } }
    var target: Int { userProfile.targetCalories }
    var remaining: Int { CalorieCalculator.remaining(target: target, consumed: consumed) }
    var isOver: Bool { CalorieCalculator.isOverTarget(target: target, consumed: consumed) }
    var overAmount: Int { CalorieCalculator.overAmount(target: target, consumed: consumed) }
    var progress: Double { min(Double(consumed) / Double(max(target, 1)), 1.0) }

    var totalProtein: Int { todayEntries.compactMap { $0.proteinGrams }.reduce(0, +) }
    var totalCarbs: Int   { todayEntries.compactMap { $0.carbsGrams }.reduce(0, +) }
    var totalFat: Int     { todayEntries.compactMap { $0.fatGrams }.reduce(0, +) }

    var body: some View {
        NavigationStack {
            List {
                // Static card sections as list header
                Section {
                    calorieRingSection
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                    macroBarSection
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                    activitySection
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }
                .listSectionSeparator(.hidden)

                // Food section — ใช้ List เพื่อ native swipe-to-delete
                Section {
                    if todayEntries.isEmpty {
                        Text("ยังไม่มีบันทึกอาหารวันนี้")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 8)
                    } else {
                        ForEach(todayEntries) { entry in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(entry.foodName)
                                        .font(.body)
                                    Text(entry.portionDescription)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text("\(entry.calories) kcal")
                                        .font(.subheadline.bold())
                                    if let p = entry.proteinGrams, let c = entry.carbsGrams, let f = entry.fatGrams {
                                        Text("P:\(p) C:\(c) F:\(f)")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .padding(.vertical, 2)
                            // ✅ native swipe-to-delete ทำงานได้ใน List
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    modelContext.delete(entry)
                                } label: {
                                    Label("ลบ", systemImage: "trash")
                                }
                            }
                        }
                    }

                    Button(action: { showingAddFood = true }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("เพิ่มอาหาร")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                    }
                } header: {
                    Text("อาหารวันนี้")
                        .font(.headline)
                        .foregroundColor(.primary)
                        .textCase(nil)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Today")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingAddFood = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .onAppear {
                viewModel.isMockMode = false
                viewModel.refreshHealthData()
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active { viewModel.refreshHealthData() }
            }
            .sheet(isPresented: $showingAddFood) { AddFoodView() }
        }
    }

    // MARK: - Calorie Ring
    private var calorieRingSection: some View {
        VStack(spacing: 12) {
            ZStack {
                // Background ring
                Circle()
                    .stroke(lineWidth: 18)
                    .foregroundColor(Color(.systemGray5))

                // Progress ring
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        isOver ? Color.red : Color.green,
                        style: StrokeStyle(lineWidth: 18, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 0.5), value: progress)

                // Center labels
                VStack(spacing: 2) {
                    Text("\(consumed)")
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .foregroundColor(isOver ? .red : .primary)
                    Text("/ \(target) kcal")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 180, height: 180)

            // Status label
            if isOver {
                Label("\(overAmount) kcal เกินเป้าหมาย", systemImage: "exclamationmark.triangle.fill")
                    .font(.subheadline.bold())
                    .foregroundColor(.red)
            } else {
                Label("\(remaining) kcal เหลือ", systemImage: "checkmark.circle.fill")
                    .font(.subheadline.bold())
                    .foregroundColor(.green)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }

    // MARK: - Macro Bars
    private var macroBarSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("โภชนาการวันนี้")
                .font(.headline)

            HStack(spacing: 16) {
                macroBar(title: "Protein", value: totalProtein, color: .blue, unit: "g")
                macroBar(title: "Carbs",   value: totalCarbs,   color: .orange, unit: "g")
                macroBar(title: "Fat",     value: totalFat,     color: .purple, unit: "g")
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }

    private func macroBar(title: String, value: Int, color: Color, unit: String) -> some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.title2.bold())
                .foregroundColor(color)
            Text(unit)
                .font(.caption2)
                .foregroundColor(.secondary)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Activity
    private var activitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("กิจกรรม")
                .font(.headline)

            HStack(spacing: 16) {
                activityItem(icon: "figure.walk", title: "ก้าว", value: "\(viewModel.steps.formatted())", color: .teal)
                activityItem(icon: "flame.fill", title: "พลังงาน", value: "\(viewModel.activeEnergy) kcal", color: .orange)
                activityItem(icon: "scalemass.fill", title: "น้ำหนัก", value: String(format: "%.1f kg", viewModel.weight), color: .indigo)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }

    private func activityItem(icon: String, title: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            Text(value)
                .font(.subheadline.bold())
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

}
