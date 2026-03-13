//
//  BarcodeScannerBuilder.swift
//  microworkout
//

import Foundation

class BarcodeScannerBuilder {
    private let component: AppComponentProtocol

    init(component: AppComponentProtocol) {
        self.component = component
    }

    func build(onScanComplete: @escaping (FoodItem) -> Void) -> BarcodeScannerView {
        let viewModel = BarcodeScannerViewModel(
            mealUseCase: MealContainer(component: component).makeUseCase(),
            navigator: Navigator.shared,
            onScanComplete: onScanComplete
        )
        return BarcodeScannerView(viewModel: viewModel)
    }
}
