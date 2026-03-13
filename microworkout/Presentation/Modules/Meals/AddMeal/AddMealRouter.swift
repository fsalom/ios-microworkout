//
//  AddMealRouter.swift
//  microworkout
//

import SwiftUI

class AddMealRouter {
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
