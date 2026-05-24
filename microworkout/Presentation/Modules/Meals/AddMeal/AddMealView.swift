//
//  AddMealView.swift
//  microworkout
//

import SwiftUI

struct AddMealView: View {
    @ObservedObject var viewModel: AddMealViewModel
    let component: AppComponentProtocol
    @Environment(\.dismiss) private var dismiss
    @State private var pendingFood: FoodItem?
    @State private var toastMessage: String?
    @State private var toastDismissTask: Task<Void, Never>?
    @State private var showScanner: Bool = false
    @State private var scannedFood: FoodItem?
    @State private var creatingMyMeal: CreateMyMealState?
    @State private var editingMyMeal: MyMeal?

    var body: some View {
        VStack(spacing: 0) {
            HeaderBar(
                mealTypeName: viewModel.uiState.selectedType.rawValue,
                onClose: { dismiss() }
            )

            // SearchField OUTSIDE the ScrollView so per-keystroke re-renders
            // don't force layout recomputation of the food list.
            SearchField(
                initialQuery: viewModel.uiState.searchQuery,
                isSearching: viewModel.uiState.isSearching,
                onTextChanged: { newText in
                    viewModel.uiState.searchQuery = newText
                    viewModel.searchFoods()
                }
            )
            .padding(.horizontal, 16)
            .padding(.top, 4)
            .padding(.bottom, 12)

            ScrollView {
                LazyVStack(spacing: 16) {
                    QuickActionsRow(
                        onScan: { showScanner = true },
                        onCreate: { viewModel.toggleManualEntry() }
                    )

                    if viewModel.uiState.showManualEntry {
                        ManualEntrySection(viewModel: viewModel)
                            .transition(.opacity)
                    }

                    if !isSearchActive && !viewModel.uiState.previousDayMeals.isEmpty {
                        PreviousDayMealsSection(
                            meals: viewModel.uiState.previousDayMeals,
                            repeatedIds: viewModel.uiState.repeatedMealIds,
                            onRepeat: { meal in
                                viewModel.repeatMeal(meal)
                                showToast("Añadido de ayer")
                            }
                        )
                    }

                    TabsBar(
                        selected: viewModel.uiState.selectedTab,
                        onSelect: { viewModel.selectTab($0) }
                    )

                    FoodListContent(
                        viewModel: viewModel,
                        component: component,
                        onSelect: { food in pendingFood = food },
                        onCreateMyMeal: { creatingMyMeal = CreateMyMealState() },
                        onEditMyMeal: { meal in editingMyMeal = meal },
                        onMyMealAdded: { meal in showToast("\(meal.name) añadida") }
                    )
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .background(Color(.systemBackground).ignoresSafeArea())
        .overlay(alignment: .bottom) {
            if let toastMessage {
                ToastBanner(message: toastMessage)
                    .padding(.bottom, 32)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: toastMessage)
        .sheet(item: $pendingFood) { food in
            QuantityPickerSheet(food: food, onConfirm: { adjusted in
                viewModel.quickAdd(adjusted)
                showToast("\(adjusted.name) añadido")
                pendingFood = nil
            }, onCancel: {
                pendingFood = nil
            })
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .fullScreenCover(isPresented: $showScanner, onDismiss: {
            if let food = scannedFood {
                scannedFood = nil
                pendingFood = food
            }
        }) {
            NavigationStack {
                BarcodeScannerBuilder(component: component).build(onScanComplete: { food in
                    scannedFood = food
                })
            }
        }
        .sheet(item: $creatingMyMeal, onDismiss: { resetSharedSearchState() }) { _ in
            CreateMyMealSheet(
                viewModel: viewModel,
                component: component,
                initialMyMeal: nil,
                onSave: { meal in
                    viewModel.saveMyMeal(meal)
                    creatingMyMeal = nil
                },
                onCancel: { creatingMyMeal = nil }
            )
        }
        .sheet(item: $editingMyMeal, onDismiss: { resetSharedSearchState() }) { meal in
            CreateMyMealSheet(
                viewModel: viewModel,
                component: component,
                initialMyMeal: meal,
                onSave: { updated in
                    viewModel.saveMyMeal(updated)
                    editingMyMeal = nil
                },
                onCancel: { editingMyMeal = nil }
            )
        }
    }

    private var isSearchActive: Bool {
        viewModel.uiState.searchQuery
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .count >= 2
    }

    /// Clears the search state shared with the CreateMyMealSheet so the parent's
    /// tabs (Recientes / Favoritos / Mis comidas) show their actual content
    /// after closing the create/edit flow.
    private func resetSharedSearchState() {
        viewModel.uiState.searchQuery = ""
        viewModel.uiState.searchResults = []
        viewModel.uiState.isSearching = false
    }

    private func showToast(_ message: String) {
        toastMessage = message
        toastDismissTask?.cancel()
        toastDismissTask = Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            await MainActor.run {
                toastMessage = nil
            }
        }
    }
}

// MARK: - Toast

private struct ToastBanner: View {
    let message: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            Text(message)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .lineLimit(1)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.green)
        .clipShape(Capsule())
        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 4)
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
    let initialQuery: String
    let isSearching: Bool
    let onTextChanged: (String) -> Void

    @State private var localText: String = ""
    @FocusState private var isFocused: Bool
    @State private var didInitialize = false
    @State private var debounceTask: Task<Void, Never>?

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(isFocused ? .green : .secondary)

            TextField("Buscar alimento o marca...", text: $localText)
                .focused($isFocused)
                .submitLabel(.search)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .onChange(of: localText) { _, _ in scheduleDebouncedPropagation() }

            if isSearching {
                ProgressView()
                    .controlSize(.small)
                    .tint(.green)
            } else if !localText.isEmpty {
                Button(action: {
                    debounceTask?.cancel()
                    localText = ""
                    onTextChanged("")
                }) {
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
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isFocused ? Color.green.opacity(0.5) : Color.clear, lineWidth: 1.5)
        )
        .onAppear {
            if !didInitialize {
                localText = initialQuery
                didInitialize = true
            }
        }
        .onChange(of: initialQuery) { _, newValue in
            // Sync from the parent when it programmatically resets the query
            // (e.g. after closing CreateMyMealSheet). Avoid feedback loops by
            // only syncing when the local text differs.
            if newValue != localText {
                debounceTask?.cancel()
                localText = newValue
            }
        }
    }

    private func scheduleDebouncedPropagation() {
        let value = localText
        debounceTask?.cancel()
        debounceTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 200_000_000) // 200ms debounce
            guard !Task.isCancelled else { return }
            onTextChanged(value)
        }
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

// MARK: - Previous Day Meals

private struct PreviousDayMealsSection: View {
    let meals: [Meal]
    let repeatedIds: Set<UUID>
    let onRepeat: (Meal) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.caption2)
                    .foregroundColor(.blue)
                Text("DE AYER")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .tracking(1)
            }

            VStack(spacing: 8) {
                ForEach(meals) { meal in
                    PreviousDayMealCard(
                        meal: meal,
                        isJustRepeated: repeatedIds.contains(meal.id),
                        onRepeat: { onRepeat(meal) }
                    )
                }
            }
        }
    }
}

private struct PreviousDayMealCard: View {
    let meal: Meal
    let isJustRepeated: Bool
    let onRepeat: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    if let name = meal.myMealName, !name.isEmpty {
                        Text(name)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.primary)
                    } else {
                        Text(meal.formattedTime)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.secondary)
                            .monospacedDigit()
                    }
                    Text("·")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("\(Int(meal.totalNutrition.calories.rounded())) kcal")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                        .monospacedDigit()
                }

                Text(itemsSummary)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 8)

            Button(action: onRepeat) {
                HStack(spacing: 4) {
                    Image(systemName: isJustRepeated ? "checkmark" : "arrow.clockwise")
                        .font(.system(size: 11, weight: .bold))
                    Text(isJustRepeated ? "Añadido" : "Repetir")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule().fill(isJustRepeated ? Color.green : Color.blue)
                )
            }
            .buttonStyle(.plain)
            .disabled(isJustRepeated)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.blue.opacity(0.18), lineWidth: 1)
        )
    }

    private var itemsSummary: String {
        let names = meal.items.map { $0.name }
        return names.joined(separator: ", ")
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
    let component: AppComponentProtocol
    let onSelect: (FoodItem) -> Void
    let onCreateMyMeal: () -> Void
    let onEditMyMeal: (MyMeal) -> Void
    let onMyMealAdded: (MyMeal) -> Void

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
            LazyVStack(spacing: 8) {
                ForEach(0..<5, id: \.self) { _ in
                    SkeletonFoodRow()
                }
            }
        } else if viewModel.uiState.searchResults.isEmpty {
            EmptyState(message: "Sin resultados para \"\(trimmedQuery)\"")
        } else {
            LazyVStack(spacing: 8) {
                ForEach(viewModel.uiState.searchResults) { food in
                    FoodRow(
                        food: food,
                        isAdded: viewModel.uiState.recentlyAddedIds.contains(food.id),
                        isFavorite: viewModel.isFavorite(food),
                        onAdd: { onSelect(food) },
                        onToggleFavorite: { viewModel.toggleFavorite(food) }
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
                LazyVStack(spacing: 8) {
                    ForEach(viewModel.uiState.recentFoods) { food in
                        FoodRow(
                            food: food,
                            isAdded: viewModel.uiState.recentlyAddedIds.contains(food.id),
                            isFavorite: viewModel.isFavorite(food),
                            onAdd: { onSelect(food) },
                            onToggleFavorite: { viewModel.toggleFavorite(food) }
                        )
                    }
                }
            }
        case .favorites:
            if viewModel.uiState.favoriteFoods.isEmpty {
                EmptyState(message: "Aún no tienes favoritos. Pulsa el corazón en un alimento para guardarlo aquí.")
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(viewModel.uiState.favoriteFoods) { food in
                        FoodRow(
                            food: food,
                            isAdded: viewModel.uiState.recentlyAddedIds.contains(food.id),
                            isFavorite: true,
                            onAdd: { onSelect(food) },
                            onToggleFavorite: { viewModel.toggleFavorite(food) }
                        )
                    }
                }
            }
        case .myFoods:
            MyMealsContent(
                viewModel: viewModel,
                onCreateNew: onCreateMyMeal,
                onEdit: onEditMyMeal,
                onMyMealAdded: onMyMealAdded
            )
        }
    }
}

private struct MyMealsContent: View {
    @ObservedObject var viewModel: AddMealViewModel
    let onCreateNew: () -> Void
    let onEdit: (MyMeal) -> Void
    let onMyMealAdded: (MyMeal) -> Void

    var body: some View {
        VStack(spacing: 12) {
            Button(action: onCreateNew) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                    Text("Crear nueva comida")
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.green)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)

            if viewModel.uiState.myMeals.isEmpty {
                EmptyState(message: "Aún no tienes comidas guardadas. Crea una para añadirla con un solo toque.")
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(viewModel.uiState.myMeals) { meal in
                        MyMealRow(
                            meal: meal,
                            onAdd: {
                                viewModel.addMyMeal(meal)
                                onMyMealAdded(meal)
                            },
                            onEdit: { onEdit(meal) },
                            onDelete: { viewModel.deleteMyMeal(id: meal.id) }
                        )
                    }
                }
            }
        }
    }
}

private struct CreateMyMealState: Identifiable {
    let id = UUID()
}

private struct MyMealRow: View {
    let meal: MyMeal
    let onAdd: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    private var summary: String {
        let count = meal.items.count
        let kcal = Int(meal.totalNutrition.calories)
        return "\(count) \(count == 1 ? "ingrediente" : "ingredientes") · \(kcal) kcal"
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "fork.knife")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.green)
                .frame(width: 32, height: 32)
                .background(Color.green.opacity(0.15))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(meal.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                Text(summary)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button(action: onAdd) {
                ZStack {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 28, height: 28)
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray5), lineWidth: 1)
        )
        .contextMenu {
            Button(action: onEdit) {
                Label("Editar", systemImage: "pencil")
            }
            Button(role: .destructive, action: onDelete) {
                Label("Eliminar", systemImage: "trash")
            }
        }
    }
}

// MARK: - Create my meal sheet (reuses the AddMeal search/scan UX)

private struct CreateMyMealSheet: View {
    @ObservedObject var viewModel: AddMealViewModel
    let component: AppComponentProtocol
    let initialMyMeal: MyMeal?
    let onSave: (MyMeal) -> Void
    let onCancel: () -> Void

    @State private var name: String = ""
    @State private var ingredients: [FoodItem] = []
    @State private var pickingIngredient: FoodItem?
    @State private var showScanner: Bool = false
    @State private var scannedFood: FoodItem?
    @State private var didInitialize: Bool = false

    private var isEditing: Bool { initialMyMeal != nil }

    private var totalKcal: Int {
        Int(ingredients.reduce(0) { $0 + $1.actualNutrition.calories })
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !ingredients.isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            CreateMyMealHeader(
                title: isEditing ? "EDITAR COMIDA" : "NUEVA COMIDA",
                name: $name,
                onClose: onCancel
            )

            SearchField(
                initialQuery: viewModel.uiState.searchQuery,
                isSearching: viewModel.uiState.isSearching,
                onTextChanged: { newText in
                    viewModel.uiState.searchQuery = newText
                    viewModel.searchFoods()
                }
            )
            .padding(.horizontal, 16)
            .padding(.top, 4)
            .padding(.bottom, 12)

            ScrollView {
                LazyVStack(spacing: 16) {
                    HStack(spacing: 10) {
                        QuickActionButton(icon: "barcode.viewfinder", title: "Escanear") {
                            showScanner = true
                        }
                    }

                    CreateMyMealFoodList(
                        viewModel: viewModel,
                        onSelect: { food in
                            print("[CreateMyMeal] picking ingredient: \(food.name)")
                            // Dismiss any keyboard (search) so the picker's "Añadir"
                            // button isn't covered.
                            UIApplication.shared.sendAction(
                                #selector(UIResponder.resignFirstResponder),
                                to: nil, from: nil, for: nil
                            )
                            pickingIngredient = food
                        }
                    )
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 120) // make room for the sticky footer
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .background(Color(.systemBackground).ignoresSafeArea())
        .onAppear {
            if !didInitialize, let existing = initialMyMeal {
                name = existing.name
                ingredients = existing.items
            }
            didInitialize = true
        }
        .overlay(alignment: .bottom) {
            if !ingredients.isEmpty {
                CreateMyMealFooter(
                    count: ingredients.count,
                    totalKcal: totalKcal,
                    canSave: canSave,
                    ingredients: ingredients,
                    onRemove: { offsets in ingredients.remove(atOffsets: offsets) },
                    onSave: {
                        let result = MyMeal(
                            id: initialMyMeal?.id ?? UUID(),
                            name: name,
                            items: ingredients,
                            createdAt: initialMyMeal?.createdAt ?? Date()
                        )
                        onSave(result)
                    }
                )
            }
        }
        .overlay {
            Group {
                if let food = pickingIngredient {
                    ZStack {
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()
                            .onTapGesture { pickingIngredient = nil }

                        QuantityPickerSheet(
                            food: food,
                            onConfirm: { adjusted in
                                print("[CreateMyMeal] confirmed ingredient: \(adjusted.name) qty=\(adjusted.quantity)")
                                ingredients.append(adjusted)
                                pickingIngredient = nil
                            },
                            onCancel: { pickingIngredient = nil }
                        )
                        .frame(maxWidth: .infinity)
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .frame(maxHeight: .infinity, alignment: .bottom)
                        .padding(.bottom, 0)
                        .ignoresSafeArea(edges: .bottom)
                        .transition(.move(edge: .bottom))
                    }
                    .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.22), value: pickingIngredient?.id)
        }
        .fullScreenCover(isPresented: $showScanner, onDismiss: {
            if let food = scannedFood {
                scannedFood = nil
                pickingIngredient = food
            }
        }) {
            NavigationStack {
                BarcodeScannerBuilder(component: component).build(onScanComplete: { food in
                    scannedFood = food
                })
            }
        }
    }
}

private struct CreateMyMealHeader: View {
    let title: String
    @Binding var name: String
    let onClose: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .tracking(1)
                TextField("Nombre", text: $name)
                    .font(.title2)
                    .fontWeight(.bold)
                    .submitLabel(.done)
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

/// Search-aware food list for the CreateMyMeal flow. When the search query has
/// content, shows search results; otherwise shows favorites first and then
/// recents (a single combined list — no tabs since there's no "Mis comidas" loop).
private struct CreateMyMealFoodList: View {
    @ObservedObject var viewModel: AddMealViewModel
    let onSelect: (FoodItem) -> Void

    private var trimmedQuery: String {
        viewModel.uiState.searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        if trimmedQuery.count >= 2 {
            if viewModel.uiState.isSearching {
                LazyVStack(spacing: 8) {
                    ForEach(0..<5, id: \.self) { _ in
                        SkeletonFoodRow()
                    }
                }
            } else if viewModel.uiState.searchResults.isEmpty {
                EmptyState(message: "Sin resultados para \"\(trimmedQuery)\"")
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(viewModel.uiState.searchResults) { food in
                        SimpleFoodPickRow(food: food, onPick: { onSelect(food) })
                    }
                }
            }
        } else {
            VStack(alignment: .leading, spacing: 16) {
                if !viewModel.uiState.favoriteFoods.isEmpty {
                    Text("Favoritos")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    LazyVStack(spacing: 8) {
                        ForEach(viewModel.uiState.favoriteFoods) { food in
                            SimpleFoodPickRow(food: food, onPick: { onSelect(food) })
                        }
                    }
                }

                if !viewModel.uiState.recentFoods.isEmpty {
                    Text("Recientes")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    LazyVStack(spacing: 8) {
                        ForEach(viewModel.uiState.recentFoods) { food in
                            SimpleFoodPickRow(food: food, onPick: { onSelect(food) })
                        }
                    }
                }

                if viewModel.uiState.favoriteFoods.isEmpty && viewModel.uiState.recentFoods.isEmpty {
                    EmptyState(message: "Busca un alimento o escanéalo para añadirlo a tu comida")
                }
            }
        }
    }
}

/// Simplified food row used inside the Create My Meal flow. The whole row is a
/// single Button so taps land reliably regardless of nested-sheet quirks. No
/// favorite toggle here — favoritos are managed from the main flow.
private struct SimpleFoodPickRow: View {
    let food: FoodItem
    let onPick: () -> Void

    var body: some View {
        Button(action: onPick) {
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

                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.green)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.systemGray5), lineWidth: 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private struct CreateMyMealFooter: View {
    let count: Int
    let totalKcal: Int
    let canSave: Bool
    let ingredients: [FoodItem]
    let onRemove: (IndexSet) -> Void
    let onSave: () -> Void

    @State private var showList = false

    var body: some View {
        VStack(spacing: 0) {
            if showList {
                List {
                    ForEach(ingredients) { item in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.name).font(.subheadline)
                                Text("\(item.formattedQuantity) · \(Int(item.actualNutrition.calories)) kcal")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                    }
                    .onDelete(perform: onRemove)
                }
                .listStyle(.plain)
                .frame(maxHeight: 220)
                .scrollContentBackground(.hidden)
            }

            HStack(spacing: 12) {
                Button(action: { withAnimation(.easeInOut(duration: 0.2)) { showList.toggle() } }) {
                    HStack(spacing: 6) {
                        Image(systemName: showList ? "chevron.down" : "chevron.up")
                            .font(.caption.bold())
                        Text("\(count) ingrediente\(count == 1 ? "" : "s") · \(totalKcal) kcal")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.primary)
                }
                .buttonStyle(.plain)

                Spacer()

                Button(action: onSave) {
                    Text("Guardar")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .background(canSave ? Color.green : Color.gray)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .disabled(!canSave)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(
            Color(.systemBackground)
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: -2)
                .ignoresSafeArea(edges: .bottom)
        )
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
    let isFavorite: Bool
    let onAdd: () -> Void
    let onToggleFavorite: () -> Void

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

            Button(action: onToggleFavorite) {
                Image(systemName: isFavorite ? "heart.fill" : "heart")
                    .font(.system(size: 16))
                    .foregroundColor(isFavorite ? .pink : .secondary)
                    .frame(width: 28, height: 28)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button(action: onAdd) {
                ZStack {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 28, height: 28)
                    Image(systemName: isAdded ? "checkmark" : "plus")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .transition(.scale.combined(with: .opacity))
                        .id(isAdded)
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

// MARK: - Skeleton (loading)

private struct SkeletonFoodRow: View {
    @State private var isPulsing = false

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color(.systemGray5))
                .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray5))
                    .frame(height: 12)
                    .frame(maxWidth: 160)
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray5))
                    .frame(height: 10)
                    .frame(maxWidth: 70)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray5))
                    .frame(width: 36, height: 12)
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray5))
                    .frame(width: 24, height: 8)
            }

            Circle()
                .fill(Color(.systemGray5))
                .frame(width: 28, height: 28)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray5), lineWidth: 1)
        )
        .opacity(isPulsing ? 0.45 : 1)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                isPulsing = true
            }
        }
    }
}

// MARK: - Quantity Picker Sheet

struct QuantityPickerSheet: View {
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
                            .toolbar {
                                ToolbarItemGroup(placement: .keyboard) {
                                    Spacer()
                                    Button("Listo") { isFocused = false }
                                        .fontWeight(.semibold)
                                }
                            }
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

struct MacroPill: View {
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
        AddMealBuilder(component: DefaultAppComponent.preview).build()
    }
}
