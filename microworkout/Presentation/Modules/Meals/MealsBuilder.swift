//
//  MealsBuilder.swift
//  microworkout
//

import Foundation

class MealsBuilder {
    func build() -> MealsView {
        let viewModel = MealsViewModel(
            router: MealsRouter(navigator: Navigator.shared),
            mealUseCase: MealContainer().makeUseCase()
        )
        return MealsView(viewModel: viewModel)
    }
}
