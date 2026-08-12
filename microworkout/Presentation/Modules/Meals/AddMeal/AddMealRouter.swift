//
//  AddMealRouter.swift
//  microworkout
//

import SwiftUI

/// Salidas de "Añadir comida", como protocolo para poder construir el ViewModel en
/// un test sin arrastrar el contenedor de dependencias entero. Mismo criterio que
/// `ProfileRouterProtocol`.
protocol AddMealRouterProtocol {
    func goToBarcodeScannerView(onScanComplete: @escaping (FoodItem) -> Void)
    func goBack()
}

class AddMealRouter: AddMealRouterProtocol {
    private var navigator: NavigatorProtocol
    private let component: AppComponentProtocol

    init(navigator: NavigatorProtocol, component: AppComponentProtocol) {
        self.navigator = navigator
        self.component = component
    }

    func goToBarcodeScannerView(onScanComplete: @escaping (FoodItem) -> Void) {
        let scannerView = BarcodeScannerBuilder(component: component).build(onScanComplete: onScanComplete)
        navigator.push(to: scannerView)
    }

    func goBack() {
        navigator.dismiss()
    }
}
