//
//  DetailWorkoutBuilder.swift
//  microworkout
//
//  Created by Fernando Salom Carratala on 6/7/23.
//

import Foundation

class DetailWorkoutBuilder {
    func build(with workout: WorkoutPlan) -> DetailWorkoutView {
        let usecase = WorkoutUseCase()
        let viewModel = DetailWorkoutViewModel(useCase: usecase, workout: workout)
        let view = DetailWorkoutView(viewModel: viewModel)
        return view
    }
}
