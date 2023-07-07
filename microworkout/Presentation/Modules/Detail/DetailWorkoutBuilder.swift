//
//  DetailWorkoutBuilder.swift
//  microworkout
//
//  Created by Fernando Salom Carratala on 6/7/23.
//

import Foundation

class DetailWorkoutBuilder {
    func build(with plan: WorkoutPlan) -> DetailWorkoutView {
        let usecase = WorkoutUseCase()
        let viewModel = DetailWorkoutViewModel(useCase: usecase, plan: plan)
        let view = DetailWorkoutView(viewModel: viewModel)
        return view
    }
}
