//
//  BarcodeScannerBuilder.swift
//  microworkout
//

import Foundation

class BarcodeScannerBuilder {
    func build(onScanComplete: @escaping (FoodItem) -> Void) -> BarcodeScannerView {
        let viewModel = BarcodeScannerViewModel(
            mealUseCase: MealContainer().makeUseCase(),
            navigator: Navigator.shared,
            onScanComplete: onScanComplete
        )
        return BarcodeScannerView(viewModel: viewModel)
    }
}
