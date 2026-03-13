//
//  AddMealBuilder.swift
//  microworkout
//

import Foundation

class AddMealBuilder {
    private let component: AppComponentProtocol

    init(component: AppComponentProtocol) {
        self.component = component
    }

    func build() -> AddMealView {
        let viewModel = AddMealViewModel(
            router: AddMealRouter(navigator: Navigator.shared, component: component),
            mealUseCase: MealContainer(component: component).makeUseCase()
        )
        return AddMealView(viewModel: viewModel)
    }
}
