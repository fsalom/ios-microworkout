//
//  BarcodeScannerViewModel.swift
//  microworkout
//

import Foundation
import AVFoundation
import SwiftUI

enum BarcodeScannerState {
    case scanning
    case loading
    case found(FoodItem)
    case notFound
    case error(String)

    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }

    var isScanning: Bool {
        if case .scanning = self { return true }
        return false
    }
}

final class BarcodeScannerViewModel: ObservableObject {
    @Published var state: BarcodeScannerState = .scanning
    @Published var scannedBarcode: String = ""
    @Published var foundItem: FoodItem?
    @Published var quantity: Double = 100
    @Published var shouldDismiss: Bool = false
    @Published var isCreatingCustom: Bool = false

    private let mealUseCase: MealUseCaseProtocol
    private let navigator: NavigatorProtocol
    private let onScanComplete: (FoodItem) -> Void

    init(
        mealUseCase: MealUseCaseProtocol,
        navigator: NavigatorProtocol,
        onScanComplete: @escaping (FoodItem) -> Void
    ) {
        self.mealUseCase = mealUseCase
        self.navigator = navigator
        self.onScanComplete = onScanComplete
    }

    func onBarcodeScanned(_ barcode: String) {
        // Solo aceptamos un escaneo cuando estamos buscando activamente.
        // Si ya hay un producto encontrado, error, sheet abierto, etc., lo ignoramos.
        guard state.isScanning, !isCreatingCustom else { return }
        scannedBarcode = barcode
        state = .loading

        Task {
            do {
                if let foodItem = try await mealUseCase.fetchFoodByBarcode(barcode) {
                    await MainActor.run {
                        self.foundItem = foodItem
                        self.state = .found(foodItem)
                    }
                } else {
                    await MainActor.run {
                        self.state = .notFound
                    }
                }
            } catch {
                await MainActor.run {
                    self.state = .error("Error al buscar el producto")
                }
            }
        }
    }

    func adjustQuantity(by amount: Double) {
        let newQuantity = quantity + amount
        if newQuantity >= 10 {
            quantity = newQuantity
        }
    }

    func addToMeal() {
        guard var item = foundItem else { return }
        item.quantity = quantity
        onScanComplete(item)
        shouldDismiss = true
    }

    func scanAgain() {
        state = .scanning
        scannedBarcode = ""
        foundItem = nil
        quantity = 100
    }

    func goBack() {
        shouldDismiss = true
    }

    // MARK: - Custom food creation

    func openCreateCustom() {
        isCreatingCustom = true
    }

    func closeCreateCustom() {
        isCreatingCustom = false
    }

    func saveCustomFood(name: String,
                        kcalPer100g: Double,
                        proteinsPer100g: Double,
                        carbsPer100g: Double,
                        fatsPer100g: Double) {
        let food = FoodItem(
            name: name,
            barcode: scannedBarcode,
            nutritionPer100g: NutritionInfo(
                calories: kcalPer100g,
                carbohydrates: carbsPer100g,
                proteins: proteinsPer100g,
                fats: fatsPer100g,
                fiber: nil
            ),
            quantity: 100
        )
        mealUseCase.saveCustomFood(food)
        foundItem = food
        quantity = 100
        isCreatingCustom = false
        state = .found(food)
    }
}
