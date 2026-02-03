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
}

final class BarcodeScannerViewModel: ObservableObject {
    @Published var state: BarcodeScannerState = .scanning
    @Published var scannedBarcode: String = ""
    @Published var foundItem: FoodItem?
    @Published var quantity: Double = 100

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
        guard !state.isLoading else { return }
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
        navigator.dismiss()
    }

    func scanAgain() {
        state = .scanning
        scannedBarcode = ""
        foundItem = nil
        quantity = 100
    }

    func goBack() {
        navigator.dismiss()
    }
}
