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
            mealUseCase: component.mealUseCase,
            userProfileUseCase: component.userProfileUseCase,
            coachUseCase: component.coachUseCase
        )
        return MealsView(viewModel: viewModel, component: component)
    }
}
