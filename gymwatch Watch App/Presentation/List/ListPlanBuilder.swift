//
//  ListPlanBuilder.swift
//  gymwatch Watch App
//
//  Created by Fernando Salom Carratala on 31/7/23.
//

import Foundation

class ListPlanBuilder {
    func build() -> ListPlanView {
        let useCase = WorkoutUseCase()

        let viewModel = ListPlanViewModel(useCase: useCase)
        let view = ListPlanView(viewModel: viewModel)
        return view
    }
}
