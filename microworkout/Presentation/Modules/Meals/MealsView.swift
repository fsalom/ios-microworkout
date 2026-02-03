//
//  MealsView.swift
//  microworkout
//

import SwiftUI

struct MealsView: View {
    @ObservedObject var viewModel: MealsViewModel
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    // Daily Summary Card
                    NutritionSummaryCard(nutrition: viewModel.uiState.todayTotals)
                        .padding(.horizontal)

                    // Meals by Type
                    ForEach(MealType.allCases) { mealType in
                        MealTypeSection(
                            mealType: mealType,
                            meals: viewModel.uiState.mealsByType[mealType] ?? [],
                            onDelete: { mealId in
                                viewModel.deleteMeal(id: mealId)
                            }
                        )
                    }
                }
                .padding(.vertical)
            }

            // Floating Add Button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        viewModel.goToAddMeal()
                    }) {
                        Image(systemName: "plus")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(width: 56, height: 56)
                            .background(Color.blue)
                            .clipShape(Circle())
                            .shadow(radius: 4)
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 20)
                }
            }
        }
        .navigationTitle("Comidas")
        .onAppear {
            viewModel.loadMeals()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                viewModel.loadMeals()
            }
        }
    }
}

// MARK: - Nutrition Summary Card

struct NutritionSummaryCard: View {
    let nutrition: NutritionInfo

    var body: some View {
        VStack(spacing: 12) {
            Text("Resumen del día")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 16) {
                NutrientItem(value: nutrition.calories, label: "kcal", color: .orange)
                NutrientItem(value: nutrition.proteins, label: "Proteínas", color: .red)
                NutrientItem(value: nutrition.carbohydrates, label: "Carbos", color: .blue)
                NutrientItem(value: nutrition.fats, label: "Grasas", color: .yellow)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct NutrientItem: View {
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

// MARK: - Meal Type Section

struct MealTypeSection: View {
    let mealType: MealType
    let meals: [Meal]
    let onDelete: (UUID) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: mealType.icon)
                    .foregroundColor(.blue)
                Text(mealType.rawValue)
                    .font(.headline)
                Spacer()
                if !meals.isEmpty {
                    Text("\(Int(meals.reduce(0) { $0 + $1.totalNutrition.calories })) kcal")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)

            if meals.isEmpty {
                Text("Sin comidas registradas")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
            } else {
                ForEach(meals) { meal in
                    MealRow(meal: meal, onDelete: {
                        onDelete(meal.id)
                    })
                }
            }
        }
    }
}

// MARK: - Meal Row

struct MealRow: View {
    let meal: Meal
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(meal.formattedTime)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(Int(meal.totalNutrition.calories)) kcal")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }

            ForEach(meal.items) { item in
                FoodItemRow(item: item)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .padding(.horizontal)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Eliminar", systemImage: "trash")
            }
        }
    }
}

// MARK: - Preview

struct MealsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            MealsBuilder().build()
        }
    }
}
