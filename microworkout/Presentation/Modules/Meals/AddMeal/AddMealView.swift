//
//  AddMealView.swift
//  microworkout
//

import SwiftUI

struct AddMealView: View {
    @ObservedObject var viewModel: AddMealViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isSearchFocused: Bool
    @State private var pendingFood: FoodItem?

    var body: some View {
        VStack(spacing: 0) {
            HeaderBar(
                mealTypeName: viewModel.uiState.selectedType.rawValue,
                onClose: { dismiss() }
            )

            ScrollView {
                VStack(spacing: 16) {
                    SearchField(
                        query: $viewModel.uiState.searchQuery,
                        isFocused: $isSearchFocused,
                        onChange: { viewModel.searchFoods() }
                    )

                    QuickActionsRow(
                        onScan: { viewModel.scanBarcode() },
                        onCreate: { viewModel.toggleManualEntry() }
                    )

                    if viewModel.uiState.showManualEntry {
                        ManualEntrySection(viewModel: viewModel)
                            .transition(.opacity)
                    }

                    TabsBar(
                        selected: viewModel.uiState.selectedTab,
                        onSelect: { viewModel.selectTab($0) }
                    )

                    FoodListContent(viewModel: viewModel, onSelect: { food in
                        pendingFood = food
                    })
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
        }
        .background(Color(.systemBackground).ignoresSafeArea())
        .sheet(item: $pendingFood) { food in
            QuantityPickerSheet(food: food, onConfirm: { adjusted in
                viewModel.quickAdd(adjusted)
                pendingFood = nil
            }, onCancel: {
                pendingFood = nil
            })
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - Header

private struct HeaderBar: View {
    let mealTypeName: String
    let onClose: () -> Void

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text("AÑADIR A")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .tracking(1)
                Text(mealTypeName)
                    .font(.title2)
                    .fontWeight(.bold)
            }
            Spacer()
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.secondary)
                    .frame(width: 32, height: 32)
                    .background(Color(.systemGray5))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }
}

// MARK: - Search

private struct SearchField: View {
    @Binding var query: String
    var isFocused: FocusState<Bool>.Binding
    let onChange: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "viewfinder")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
            TextField("Buscar alimento o marca...", text: $query)
                .focused(isFocused)
                .onChange(of: query) { _, _ in onChange() }
                .submitLabel(.search)
            if !query.isEmpty {
                Button(action: { query = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Quick Actions

private struct QuickActionsRow: View {
    let onScan: () -> Void
    let onCreate: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            QuickActionButton(icon: "barcode.viewfinder", title: "Escanear", action: onScan)
            QuickActionButton(icon: "plus", title: "Crear", action: onCreate)
        }
    }
}

private struct QuickActionButton: View {
    let icon: String
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .foregroundColor(.primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Tabs

private struct TabsBar: View {
    let selected: AddMealListTab
    let onSelect: (AddMealListTab) -> Void

    var body: some View {
        HStack(spacing: 24) {
            ForEach(AddMealListTab.allCases) { tab in
                Button(action: { onSelect(tab) }) {
                    VStack(spacing: 6) {
                        Text(tab.rawValue)
                            .font(.subheadline)
                            .fontWeight(selected == tab ? .bold : .regular)
                            .foregroundColor(selected == tab ? .primary : .secondary)
                        Rectangle()
                            .fill(selected == tab ? Color.green : Color.clear)
                            .frame(height: 2)
                    }
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
        .padding(.top, 4)
    }
}

// MARK: - Food List Content

private struct FoodListContent: View {
    @ObservedObject var viewModel: AddMealViewModel
    let onSelect: (FoodItem) -> Void

    private var trimmedQuery: String {
        viewModel.uiState.searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        Group {
            if trimmedQuery.count >= 2 {
                searchResults
            } else {
                tabContent
            }
        }
    }

    @ViewBuilder
    private var searchResults: some View {
        if viewModel.uiState.isSearching {
            HStack { Spacer(); ProgressView(); Spacer() }
                .padding(.top, 16)
        } else if viewModel.uiState.searchResults.isEmpty {
            EmptyState(message: "Sin resultados para \"\(trimmedQuery)\"")
        } else {
            VStack(spacing: 8) {
                ForEach(viewModel.uiState.searchResults) { food in
                    FoodRow(
                        food: food,
                        isAdded: viewModel.uiState.recentlyAddedIds.contains(food.id),
                        onAdd: { onSelect(food) }
                    )
                }
            }
        }
    }

    @ViewBuilder
    private var tabContent: some View {
        switch viewModel.uiState.selectedTab {
        case .recent:
            if viewModel.uiState.recentFoods.isEmpty {
                EmptyState(message: "Aún no has añadido alimentos")
            } else {
                VStack(spacing: 8) {
                    ForEach(viewModel.uiState.recentFoods) { food in
                        FoodRow(
                            food: food,
                            isAdded: viewModel.uiState.recentlyAddedIds.contains(food.id),
                            onAdd: { onSelect(food) }
                        )
                    }
                }
            }
        case .favorites:
            EmptyState(message: "Próximamente")
        case .myFoods:
            EmptyState(message: "Próximamente")
        }
    }
}

private struct EmptyState: View {
    let message: String

    var body: some View {
        Text(message)
            .font(.subheadline)
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)
    }
}

// MARK: - Food Row

private struct FoodRow: View {
    let food: FoodItem
    let isAdded: Bool
    let onAdd: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "leaf.fill")
                .font(.system(size: 14))
                .foregroundColor(.green)
                .frame(width: 32, height: 32)
                .background(Color.green.opacity(0.15))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(food.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                Text(food.formattedQuantity)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(food.actualNutrition.calories))")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                Text("kcal")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Button(action: onAdd) {
                ZStack {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 28, height: 28)
                    Image(systemName: isAdded ? "checkmark" : "plus")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .transition(.scale.combined(with: .opacity))
                        .id(isAdded) // forces re-render with transition on toggle
                }
            }
            .buttonStyle(.plain)
            .disabled(isAdded)
            .animation(.easeInOut(duration: 0.2), value: isAdded)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isAdded ? Color.green.opacity(0.4) : Color(.systemGray5), lineWidth: 1)
        )
    }
}

// MARK: - Quantity Picker Sheet

private struct QuantityPickerSheet: View {
    let food: FoodItem
    let onConfirm: (FoodItem) -> Void
    let onCancel: () -> Void

    @State private var quantityText: String
    @FocusState private var isFocused: Bool

    init(food: FoodItem, onConfirm: @escaping (FoodItem) -> Void, onCancel: @escaping () -> Void) {
        self.food = food
        self.onConfirm = onConfirm
        self.onCancel = onCancel
        _quantityText = State(initialValue: Self.formatQuantity(food.quantity))
    }

    private var quantity: Double {
        let normalized = quantityText.replacingOccurrences(of: ",", with: ".")
        return Double(normalized) ?? 0
    }

    private var adjustedFood: FoodItem {
        var copy = food
        copy.quantity = quantity
        return copy
    }

    private var nutrition: NutritionInfo {
        adjustedFood.actualNutrition
    }

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 4) {
                Text(food.name)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                Text("\(Int(nutrition.calories)) kcal")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.green)
            }
            .padding(.top, 8)

            HStack(spacing: 24) {
                MacroPill(label: "P", value: nutrition.proteins, color: .green)
                MacroPill(label: "C", value: nutrition.carbohydrates, color: .orange)
                MacroPill(label: "G", value: nutrition.fats, color: Color.orange.opacity(0.7))
            }

            VStack(spacing: 8) {
                Text("Cantidad")
                    .font(.caption)
                    .foregroundColor(.secondary)
                HStack(spacing: 12) {
                    Button(action: adjustBy(-10)) {
                        Image(systemName: "minus")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.primary)
                            .frame(width: 36, height: 36)
                            .background(Color(.systemGray5))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)

                    HStack(spacing: 4) {
                        TextField("100", text: $quantityText)
                            .keyboardType(.decimalPad)
                            .focused($isFocused)
                            .multilineTextAlignment(.center)
                            .font(.system(size: 22, weight: .bold))
                            .frame(minWidth: 60)
                        Text("g")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                    Button(action: adjustBy(10)) {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.primary)
                            .frame(width: 36, height: 36)
                            .background(Color(.systemGray5))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
            }

            Spacer()

            Button(action: { onConfirm(adjustedFood) }) {
                Text("Añadir")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(quantity > 0 ? Color.green : Color.gray)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
            .disabled(quantity <= 0)
        }
        .padding(20)
        .background(Color(.systemBackground).ignoresSafeArea())
    }

    private func adjustBy(_ delta: Double) -> () -> Void {
        return {
            let next = max(0, quantity + delta)
            quantityText = Self.formatQuantity(next)
        }
    }

    private static func formatQuantity(_ value: Double) -> String {
        if value == floor(value) { return "\(Int(value))" }
        return String(format: "%.1f", value)
    }
}

private struct MacroPill: View {
    let label: String
    let value: Double
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text("\(Int(value))g")
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            Text(label)
                .font(.caption2)
                .foregroundColor(color)
                .fontWeight(.semibold)
        }
    }
}

// MARK: - Manual Entry (kept for "Crear" toggle)

private struct ManualEntrySection: View {
    @ObservedObject var viewModel: AddMealViewModel

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Crear alimento")
                    .font(.headline)
                Spacer()
                Button(action: { viewModel.toggleManualEntry() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }

            TextField("Nombre", text: $viewModel.uiState.manualName)
                .textFieldStyle(.roundedBorder)

            HStack(spacing: 8) {
                TextField("Cantidad (g)", text: $viewModel.uiState.manualQuantity)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
                TextField("kcal", text: $viewModel.uiState.manualCalories)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
            }

            HStack(spacing: 8) {
                TextField("Proteína (g)", text: $viewModel.uiState.manualProteins)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
                TextField("Carbos (g)", text: $viewModel.uiState.manualCarbs)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
                TextField("Grasa (g)", text: $viewModel.uiState.manualFats)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
            }

            Button(action: {
                viewModel.addManualFood()
                if let item = viewModel.uiState.items.last {
                    viewModel.quickAdd(item)
                    viewModel.removeFoodItem(at: viewModel.uiState.items.count - 1)
                }
            }) {
                Text("Añadir")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.green)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
            .disabled(!viewModel.uiState.canAddManual)
            .opacity(viewModel.uiState.canAddManual ? 1 : 0.5)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}

#Preview {
    NavigationStack {
        AddMealBuilder(component: DefaultAppComponent()).build()
    }
}
