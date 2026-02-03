//
//  MealsRouter.swift
//  microworkout
//

import SwiftUI

class MealsRouter {
    private var navigator: NavigatorProtocol

    init(navigator: NavigatorProtocol) {
        self.navigator = navigator
    }

    func goToAddMeal() {
        navigator.push(to: AddMealBuilder().build())
    }

    func goBack() {
        navigator.dismiss()
    }
}
