//
//  AddMealView.swift
//  microworkout
//

import SwiftUI

struct AddMealView: View {
    @ObservedObject var viewModel: AddMealViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Meal Type Selector
                MealTypeSelector(
                    selectedType: viewModel.uiState.selectedType,
                    onSelect: { type in
                        viewModel.selectMealType(type)
                    }
                )

                // Time Picker
                TimePicker(selectedTime: $viewModel.uiState.selectedTime)

                // Added Items
                if !viewModel.uiState.items.isEmpty {
                    AddedItemsSection(viewModel: viewModel)
                }

                // Action Buttons
                ActionButtonsSection(viewModel: viewModel)

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
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
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
                        Button(action: {
                            onSelect(type)
                        }) {
                            HStack {
                                Image(systemName: type.icon)
                                Text(type.rawValue)
                            }
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
            Text("Hora")
                .font(.headline)
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

// MARK: - Added Items Section

struct AddedItemsSection: View {
    @ObservedObject var viewModel: AddMealViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Alimentos añadidos")
                .font(.headline)
                .padding(.horizontal)

            ForEach(Array(viewModel.uiState.items.enumerated()), id: \.element.id) { index, item in
                EditableFoodItemRow(
                    item: Binding(
                        get: { viewModel.uiState.items[index] },
                        set: { viewModel.updateFoodItem(at: index, with: $0) }
                    ),
                    onDelete: {
                        viewModel.removeFoodItem(at: index)
                    }
                )
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - Action Buttons Section

struct ActionButtonsSection: View {
    @ObservedObject var viewModel: AddMealViewModel

    var body: some View {
        VStack(spacing: 12) {
            Button(action: {
                viewModel.scanBarcode()
            }) {
                HStack {
                    Image(systemName: "barcode.viewfinder")
                    Text("Escanear código de barras")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }

            Button(action: {
                viewModel.toggleManualEntry()
            }) {
                HStack {
                    Image(systemName: viewModel.uiState.showManualEntry ? "xmark" : "plus")
                    Text(viewModel.uiState.showManualEntry ? "Cancelar entrada manual" : "Añadir manualmente")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray5))
                .foregroundColor(.primary)
                .cornerRadius(12)
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Manual Entry Section

struct ManualEntrySection: View {
    @ObservedObject var viewModel: AddMealViewModel

    var body: some View {
        VStack(spacing: 12) {
            Text("Entrada manual")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            TextField("Nombre del alimento", text: $viewModel.uiState.manualName)
                .textFieldStyle(.roundedBorder)

            HStack(spacing: 12) {
                VStack(alignment: .leading) {
                    Text("Cantidad (g)")
                        .font(.caption)
                    TextField("100", text: $viewModel.uiState.manualQuantity)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.numberPad)
                }

                VStack(alignment: .leading) {
                    Text("Calorías")
                        .font(.caption)
                    TextField("0", text: $viewModel.uiState.manualCalories)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.numberPad)
                }
            }

            HStack(spacing: 12) {
                VStack(alignment: .leading) {
                    Text("Carbos (g)")
                        .font(.caption)
                    TextField("0", text: $viewModel.uiState.manualCarbs)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.numberPad)
                }

                VStack(alignment: .leading) {
                    Text("Proteínas (g)")
                        .font(.caption)
                    TextField("0", text: $viewModel.uiState.manualProteins)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.numberPad)
                }

                VStack(alignment: .leading) {
                    Text("Grasas (g)")
                        .font(.caption)
                    TextField("0", text: $viewModel.uiState.manualFats)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.numberPad)
                }
            }

            Button(action: {
                viewModel.addManualFood()
            }) {
                Text("Añadir alimento")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(viewModel.uiState.canAddManual ? Color.green : Color.gray)
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

// MARK: - Save Button

struct SaveButton: View {
    @ObservedObject var viewModel: AddMealViewModel

    var body: some View {
        Button(action: {
            viewModel.saveMeal()
        }) {
            if viewModel.uiState.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            } else {
                Text("Guardar comida")
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(viewModel.uiState.canSave ? Color.blue : Color.gray)
        .foregroundColor(.white)
        .cornerRadius(12)
        .padding(.horizontal)
        .disabled(!viewModel.uiState.canSave || viewModel.uiState.isLoading)
    }
}

#Preview {
    NavigationStack {
        AddMealBuilder().build()
    }
}
