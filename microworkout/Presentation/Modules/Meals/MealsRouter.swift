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

    func goToAddMeal() {
        navigator.push(to: AddMealBuilder(component: component).build())
    }

    func goBack() {
        navigator.dismiss()
    }
}
