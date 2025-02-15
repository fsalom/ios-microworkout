//
//  HomeBuilder.swift
//  microworkout
//
//  Created by Fernando Salom Carratala on 8/6/23.
//

import Foundation

class HomeTrainingBuilder {
    func build() -> HomeTrainingView {
        let useCase = WorkoutUseCase()

        let viewModel = HomeTrainingViewModel(useCase: useCase)
        let view = HomeTrainingView(viewModel: viewModel)
        return view
    }
}
