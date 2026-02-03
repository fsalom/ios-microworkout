//
//  AddMealRouter.swift
//  microworkout
//

import SwiftUI

class AddMealRouter {
    private var navigator: NavigatorProtocol

    init(navigator: NavigatorProtocol) {
        self.navigator = navigator
    }

    func goToBarcodeScannerView(onScanComplete: @escaping (FoodItem) -> Void) {
        let scannerView = BarcodeScannerBuilder().build(onScanComplete: onScanComplete)
        navigator.push(to: scannerView)
    }

    func goBack() {
        navigator.dismiss()
    }
}
