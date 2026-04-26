//
//  MealsRouter.swift
//  microworkout
//

import SwiftUI

class MealsRouter {
    private var navigator: NavigatorProtocol
    private let component: AppComponentProtocol

    init(navigator: NavigatorProtocol, component: AppComponentProtocol) {
        self.navigator = navigator
        self.component = component
    }

    func goToAddMeal(prefilledType: MealType? = nil) {
        navigator.push(to: AddMealBuilder(component: component).build(prefilledType: prefilledType))
    }

    func goToBarcodeScanner() {
        navigator.push(to: BarcodeScannerBuilder(component: component).build(onScanComplete: { _ in }))
    }

    func goBack() {
        navigator.dismiss()
    }
}
