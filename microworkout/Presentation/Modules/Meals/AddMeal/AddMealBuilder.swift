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

    func build(prefilledType: MealType? = nil) -> AddMealView {
        let viewModel = AddMealViewModel(
            router: AddMealRouter(navigator: Navigator.shared, component: component),
            mealUseCase: MealContainer(component: component).makeUseCase()
        )
        if let prefilledType = prefilledType {
            viewModel.selectMealType(prefilledType)
        }
        return AddMealView(viewModel: viewModel, component: component)
    }
}
