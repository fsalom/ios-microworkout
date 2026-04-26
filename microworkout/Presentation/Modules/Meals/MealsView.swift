//
//  MealsView.swift
//  microworkout
//

import SwiftUI

struct MealsView: View {
    @ObservedObject var viewModel: MealsViewModel
    let component: AppComponentProtocol
    @Environment(\.scenePhase) private var scenePhase
    @State private var addMealSheet: AddMealSheetData?

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    DateHeader(
                        date: viewModel.uiState.selectedDate,
                        canGoNext: viewModel.canGoToNextDay,
                        onPrevious: { viewModel.goToPreviousDay() },
                        onNext: { viewModel.goToNextDay() }
                    )
                    .padding(.horizontal)

                    SummaryCard(state: viewModel.uiState)
                        .padding(.horizontal)

                    ActionButtonsRow(
                        onScan: { viewModel.goToBarcodeScanner() },
                        onSearch: { addMealSheet = AddMealSheetData(mealType: nil) }
                    )
                    .padding(.horizontal)

                    ForEach(MealType.allCases) { type in
                        MealSectionCard(
                            type: type,
                            meals: viewModel.uiState.mealsByType[type] ?? [],
                            onAdd: { addMealSheet = AddMealSheetData(mealType: type) },
                            onDelete: { mealId in viewModel.deleteMeal(id: mealId) }
                        )
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            viewModel.loadMeals()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                viewModel.loadMeals()
            }
        }
        .sheet(item: $addMealSheet, onDismiss: { viewModel.loadMeals() }) { data in
            AddMealBuilder(component: component).build(prefilledType: data.mealType)
        }
    }
}

struct AddMealSheetData: Identifiable {
    let id = UUID()
    let mealType: MealType?
}

// MARK: - Date Header

private struct DateHeader: View {
    let date: Date
    let canGoNext: Bool
    let onPrevious: () -> Void
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Button(action: onPrevious) {
                    Image(systemName: "chevron.left")
                        .font(.headline)
                        .foregroundColor(.primary)
                        .frame(width: 32, height: 32)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)

                Spacer()

                Text(formattedDate)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .tracking(1)

                Spacer()

                Button(action: onNext) {
                    Image(systemName: "chevron.right")
                        .font(.headline)
                        .foregroundColor(canGoNext ? .primary : .secondary.opacity(0.5))
                        .frame(width: 32, height: 32)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .disabled(!canGoNext)
            }

            Text("Alimentación")
                .font(.title)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var formattedDate: String {
        let cal = Calendar.current
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_ES")
        formatter.dateFormat = "EEE d MMM"
        let datePart = formatter.string(from: date).uppercased()

        if cal.isDateInToday(date) {
            return "HOY · \(datePart)"
        } else if cal.isDateInYesterday(date) {
            return "AYER · \(datePart)"
        } else {
            return datePart
        }
    }
}

// MARK: - Summary Card

private struct SummaryCard: View {
    let state: MealsUiState

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                CalorieDonut(
                    progress: state.calorieProgress,
                    remaining: state.caloriesRemaining,
                    hasTarget: state.dailyCalorieTarget != nil
                )

                VStack(spacing: 12) {
                    MacroRow(
                        label: "Proteína",
                        current: state.todayTotals.proteins,
                        target: state.macroTargets?.proteins,
                        color: .green
                    )
                    MacroRow(
                        label: "Carbos",
                        current: state.todayTotals.carbohydrates,
                        target: state.macroTargets?.carbohydrates,
                        color: .orange
                    )
                    MacroRow(
                        label: "Grasa",
                        current: state.todayTotals.fats,
                        target: state.macroTargets?.fats,
                        color: Color.orange.opacity(0.7)
                    )
                }
                .frame(maxWidth: .infinity)
            }

            Divider()

            HStack(spacing: 0) {
                StatColumn(
                    label: "OBJETIVO",
                    value: state.dailyCalorieTarget.map { "\(Int($0))" } ?? "—"
                )
                StatColumn(
                    label: "COMIDO",
                    value: "\(Int(state.todayTotals.calories))"
                )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
}

private struct StatColumn: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .tracking(1)
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Calorie Donut

private struct CalorieDonut: View {
    let progress: Double
    let remaining: Double
    let hasTarget: Bool

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color(.systemGray5), lineWidth: 10)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(Color.green, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.4), value: progress)

            VStack(spacing: 0) {
                Text(displayValue)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.primary)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                Text(displayLabel)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .tracking(1)
            }
            .padding(.horizontal, 8)
        }
        .frame(width: 120, height: 120)
    }

    private var displayValue: String {
        guard hasTarget else { return "—" }
        return "\(Int(abs(remaining)))"
    }

    private var displayLabel: String {
        guard hasTarget else { return "KCAL" }
        return remaining >= 0 ? "RESTAN" : "PASADAS"
    }
}

// MARK: - Macro Row

private struct MacroRow: View {
    let label: String
    let current: Double
    let target: Double?
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                Spacer()
                HStack(spacing: 2) {
                    Text("\(Int(current))")
                        .font(.subheadline)
                        .fontWeight(.bold)
                    if let target = target {
                        Text("/\(Int(target))g")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        Text("g")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            MealsProgressBar(progress: barProgress, color: color, height: 4)
        }
    }

    private var barProgress: Double {
        guard let target = target, target > 0 else { return 0 }
        return min(current / target, 1.0)
    }
}

// MARK: - Progress Bar

private struct MealsProgressBar: View {
    let progress: Double
    let color: Color
    let height: CGFloat

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color(.systemGray5))
                    .frame(height: height)
                Capsule()
                    .fill(color)
                    .frame(width: geo.size.width * CGFloat(progress), height: height)
            }
        }
        .frame(height: height)
    }
}

// MARK: - Action Buttons

private struct ActionButtonsRow: View {
    let onScan: () -> Void
    let onSearch: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onScan) {
                ActionButtonLabel(icon: "barcode.viewfinder", title: "Escanear", filled: true)
            }
            .buttonStyle(.plain)

            Button(action: onSearch) {
                ActionButtonLabel(icon: "plus", title: "Buscar", filled: false)
            }
            .buttonStyle(.plain)
        }
    }
}

private struct ActionButtonLabel: View {
    let icon: String
    let title: String
    let filled: Bool

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .foregroundColor(filled ? .white : .primary)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(filled ? Color.green : Color(.secondarySystemGroupedBackground))
                .shadow(color: Color.black.opacity(filled ? 0 : 0.05), radius: 8, x: 0, y: 2)
        )
    }
}

// MARK: - Meal Section Card

private struct MealSectionCard: View {
    let type: MealType
    let meals: [Meal]
    let onAdd: () -> Void
    let onDelete: (UUID) -> Void

    private var totalNutrition: NutritionInfo {
        meals.reduce(.zero) { $0 + $1.totalNutrition }
    }

    private var allItems: [FoodItem] {
        meals.flatMap { $0.items }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: type.icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.green)
                    .frame(width: 32, height: 32)
                    .background(Color.green.opacity(0.15))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(type.rawValue)
                        .font(.headline)
                        .fontWeight(.bold)
                    Text(allItems.isEmpty ? "Sin comidas registradas" : macrosSummary)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button(action: onAdd) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.green)
                        .frame(width: 28, height: 28)
                        .background(Color.green.opacity(0.15))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(14)

            if !allItems.isEmpty {
                Divider().padding(.leading, 14)

                VStack(spacing: 0) {
                    ForEach(Array(allItems.enumerated()), id: \.element.id) { index, item in
                        FoodItemRowView(item: item)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)

                        if index < allItems.count - 1 {
                            Divider().padding(.leading, 14)
                        }
                    }
                }
                .padding(.bottom, 6)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .swipeActions(edge: .trailing) {
            // ForEach swipe actions per meal could be added; deletion is per-meal so we skip section-wide
        }
    }

    private var macrosSummary: String {
        let kcal = Int(totalNutrition.calories)
        let p = Int(totalNutrition.proteins)
        let c = Int(totalNutrition.carbohydrates)
        let f = Int(totalNutrition.fats)
        return "\(kcal) kcal · P\(p) · C\(c) · F\(f)"
    }
}

// MARK: - Food Item Row

private struct FoodItemRowView: View {
    let item: FoodItem

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                Text(item.formattedQuantity)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(item.actualNutrition.calories))")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                Text(macroSummary)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var macroSummary: String {
        let n = item.actualNutrition
        return "P\(Int(n.proteins))·C\(Int(n.carbohydrates))·F\(Int(n.fats))"
    }
}

// MARK: - Nutrition Summary Card (legacy, used by AddMealView)

struct NutritionSummaryCard: View {
    let nutrition: NutritionInfo

    var body: some View {
        VStack(spacing: 12) {
            Text("Resumen del día")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 16) {
                NutrientItem(value: nutrition.calories, label: "kcal", color: .orange)
                NutrientItem(value: nutrition.proteins, label: "Proteínas", color: .green)
                NutrientItem(value: nutrition.carbohydrates, label: "Carbos", color: .orange)
                NutrientItem(value: nutrition.fats, label: "Grasas", color: Color.orange.opacity(0.7))
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

private struct NutrientItem: View {
    let value: Double
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(String(format: "%.0f", value))
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview

struct MealsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            MealsBuilder(component: DefaultAppComponent()).build()
        }
    }
}
