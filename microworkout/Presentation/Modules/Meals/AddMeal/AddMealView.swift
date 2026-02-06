//
//  AddMealView.swift
//  microworkout
//

import SwiftUI

struct AddMealView: View {
    @ObservedObject var viewModel: AddMealViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    // Meal Type Selector
                    MealTypeSelector(
                        selectedType: viewModel.uiState.selectedType,
                        onSelect: { viewModel.selectMealType($0) }
                    )

                    // Time Picker
                    TimePicker(selectedTime: $viewModel.uiState.selectedTime)

                    // Recent Foods
                    if !viewModel.uiState.recentFoods.isEmpty {
                        RecentFoodsSection(viewModel: viewModel)
                    }

                    // Search Section
                    FoodSearchSection(viewModel: viewModel, isSearchFocused: $isSearchFocused)

                    // Added Items
                    if !viewModel.uiState.items.isEmpty {
                        AddedItemsSection(viewModel: viewModel)
                    }

                    // Manual Entry Section
                    if viewModel.uiState.showManualEntry {
                        ManualEntrySection(viewModel: viewModel)
                    }

                    // Nutrition Summary
                    if !viewModel.uiState.items.isEmpty {
                        NutritionSummaryCard(nutrition: viewModel.uiState.totalNutrition)
                            .padding(.horizontal)
                    }

                    // Save Button
                    SaveButton(viewModel: viewModel)

                    Spacer(minLength: 50)
                }
                .padding(.vertical)
            }
        }
        .navigationTitle("Añadir comida")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancelar") {
                    dismiss()
                }
            }
        }
        .alert("Error", isPresented: .constant(viewModel.uiState.error != nil)) {
            Button("OK") {
                viewModel.uiState.error = nil
            }
        } message: {
            Text(viewModel.uiState.error ?? "")
        }
    }
}

// MARK: - Meal Type Selector

struct MealTypeSelector: View {
    let selectedType: MealType
    let onSelect: (MealType) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tipo de comida")
                .font(.headline)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(MealType.allCases) { type in
                        Button(action: { onSelect(type) }) {
                            HStack(spacing: 6) {
                                Image(systemName: type.icon)
                                Text(type.rawValue)
                            }
                            .font(.subheadline)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(selectedType == type ? Color.blue : Color(.systemGray5))
                            .foregroundColor(selectedType == type ? .white : .primary)
                            .cornerRadius(20)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - Time Picker

struct TimePicker: View {
    @Binding var selectedTime: Date

    var body: some View {
        HStack {
            Image(systemName: "clock")
                .foregroundColor(.blue)
            Text("Hora")
                .font(.subheadline)
            Spacer()
            DatePicker("", selection: $selectedTime, displayedComponents: .hourAndMinute)
                .labelsHidden()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

// MARK: - Recent Foods Section

struct RecentFoodsSection: View {
    @ObservedObject var viewModel: AddMealViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recientes")
                .font(.headline)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(viewModel.uiState.recentFoods) { food in
                        Button(action: { viewModel.addRecentFood(food) }) {
                            HStack(spacing: 4) {
                                Image(systemName: "clock.arrow.circlepath")
                                    .font(.caption2)
                                Text(food.name)
                                    .lineLimit(1)
                            }
                            .font(.subheadline)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(.systemGray5))
                            .foregroundColor(.primary)
                            .cornerRadius(16)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - Food Search Section

struct FoodSearchSection: View {
    @ObservedObject var viewModel: AddMealViewModel
    var isSearchFocused: FocusState<Bool>.Binding

    var body: some View {
        VStack(spacing: 12) {
            // Search Bar
            HStack(spacing: 12) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Buscar alimento...", text: $viewModel.uiState.searchQuery)
                        .focused(isSearchFocused)
                        .autocorrectionDisabled()
                        .onChange(of: viewModel.uiState.searchQuery) { _, _ in
                            viewModel.searchFoods()
                        }
                    if !viewModel.uiState.searchQuery.isEmpty {
                        Button(action: { viewModel.clearSearch() }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(10)
                .background(Color(.systemGray6))
                .cornerRadius(10)

                // Barcode button
                Button(action: { viewModel.scanBarcode() }) {
                    Image(systemName: "barcode.viewfinder")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
            }
            .padding(.horizontal)

            // Search Results or Actions
            if viewModel.uiState.isSearching {
                HStack {
                    ProgressView()
                    Text("Buscando...")
                        .foregroundColor(.secondary)
                }
                .padding()
            } else if !viewModel.uiState.searchResults.isEmpty {
                SearchResultsList(
                    results: viewModel.uiState.searchResults,
                    onSelect: { viewModel.selectSearchResult($0) }
                )
            } else if viewModel.uiState.searchQuery.count >= 2 {
                VStack(spacing: 8) {
                    Text("No se encontraron resultados")
                        .foregroundColor(.secondary)
                    Button(action: { viewModel.toggleManualEntry() }) {
                        Text("Añadir manualmente")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                }
                .padding()
            } else {
                // Quick actions
                HStack(spacing: 12) {
                    QuickActionButton(
                        icon: "plus.circle",
                        title: "Manual",
                        color: .green
                    ) {
                        viewModel.toggleManualEntry()
                    }

                    QuickActionButton(
                        icon: "barcode",
                        title: "Escanear",
                        color: .blue
                    ) {
                        viewModel.scanBarcode()
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                Text(title)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(color.opacity(0.1))
            .foregroundColor(color)
            .cornerRadius(12)
        }
    }
}

// MARK: - Search Results List

struct SearchResultsList: View {
    let results: [FoodItem]
    let onSelect: (FoodItem) -> Void

    var body: some View {
        VStack(spacing: 0) {
            ForEach(results.prefix(10)) { item in
                Button(action: { onSelect(item) }) {
                    SearchResultRow(item: item)
                }
                .buttonStyle(.plain)

                if item.id != results.prefix(10).last?.id {
                    Divider().padding(.leading, 60)
                }
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct SearchResultRow: View {
    let item: FoodItem

    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail
            if let imageUrl = item.imageUrl, let url = URL(string: imageUrl) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 44, height: 44)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    default:
                        FoodPlaceholderImage()
                    }
                }
            } else {
                FoodPlaceholderImage()
            }

            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.subheadline)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                HStack(spacing: 8) {
                    Text("\(Int(item.nutritionPer100g.calories)) kcal")
                        .foregroundColor(.orange)
                    Text("P: \(Int(item.nutritionPer100g.proteins))g")
                        .foregroundColor(.red)
                    Text("C: \(Int(item.nutritionPer100g.carbohydrates))g")
                        .foregroundColor(.blue)
                }
                .font(.caption)
            }

            Spacer()

            Image(systemName: "plus.circle.fill")
                .font(.title2)
                .foregroundColor(.blue)
        }
        .padding(12)
    }
}

struct FoodPlaceholderImage: View {
    var body: some View {
        Image(systemName: "leaf.fill")
            .foregroundColor(.green)
            .frame(width: 44, height: 44)
            .background(Color.green.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Added Items Section

struct AddedItemsSection: View {
    @ObservedObject var viewModel: AddMealViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Alimentos añadidos")
                    .font(.headline)
                Spacer()
                Text("\(viewModel.uiState.items.count)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)

            VStack(spacing: 8) {
                ForEach(Array(viewModel.uiState.items.enumerated()), id: \.element.id) { index, item in
                    EditableFoodItemRow(
                        item: Binding(
                            get: { viewModel.uiState.items[index] },
                            set: { viewModel.updateFoodItem(at: index, with: $0) }
                        ),
                        onDelete: { viewModel.removeFoodItem(at: index) }
                    )
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Manual Entry Section

struct ManualEntrySection: View {
    @ObservedObject var viewModel: AddMealViewModel

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Entrada manual")
                    .font(.headline)
                Spacer()
                Button(action: { viewModel.toggleManualEntry() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }

            TextField("Nombre del alimento", text: $viewModel.uiState.manualName)
                .textFieldStyle(.roundedBorder)

            HStack(spacing: 12) {
                NutrientTextField(label: "Cantidad (g)", text: $viewModel.uiState.manualQuantity)
                NutrientTextField(label: "Calorías", text: $viewModel.uiState.manualCalories)
            }

            HStack(spacing: 12) {
                NutrientTextField(label: "Proteínas (g)", text: $viewModel.uiState.manualProteins)
                NutrientTextField(label: "Carbos (g)", text: $viewModel.uiState.manualCarbs)
                NutrientTextField(label: "Grasas (g)", text: $viewModel.uiState.manualFats)
            }

            Button(action: { viewModel.addManualFood() }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Añadir alimento")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(viewModel.uiState.canAddManual ? Color.green : Color.gray.opacity(0.3))
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(!viewModel.uiState.canAddManual)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct NutrientTextField: View {
    let label: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            TextField("0", text: $text)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.decimalPad)
        }
    }
}

// MARK: - Save Button

struct SaveButton: View {
    @ObservedObject var viewModel: AddMealViewModel

    var body: some View {
        Button(action: { viewModel.saveMeal() }) {
            HStack {
                if viewModel.uiState.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Guardar comida")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(viewModel.uiState.canSave ? Color.blue : Color.gray.opacity(0.3))
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(!viewModel.uiState.canSave || viewModel.uiState.isLoading)
        .padding(.horizontal)
    }
}

#Preview {
    NavigationStack {
        AddMealBuilder().build()
    }
}
