//
//  MealsBuilder.swift
//  microworkout
//

import Foundation

class MealsBuilder {
    private let component: AppComponentProtocol

    init(component: AppComponentProtocol) {
        self.component = component
    }

    func build() -> MealsView {
        let viewModel = MealsViewModel(
            router: MealsRouter(navigator: Navigator.shared, component: component),
            mealUseCase: MealContainer(component: component).makeUseCase()
        )
        return MealsView(viewModel: viewModel)
    }
}
