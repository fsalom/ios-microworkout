//
//  AddMealBuilder.swift
//  microworkout
//

import Foundation

class AddMealBuilder {
    func build() -> AddMealView {
        let viewModel = AddMealViewModel(
            router: AddMealRouter(navigator: Navigator.shared),
            mealUseCase: MealContainer().makeUseCase()
        )
        return AddMealView(viewModel: viewModel)
    }
}
