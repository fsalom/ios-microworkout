//
//  DetailWorkoutBuilder.swift
//  gymwatch Watch App
//
//  Created by Fernando Salom Carratala on 31/7/23.
//

import Foundation

class DetailWorkoutBuilder {
    func build(with workout: WorkoutPlan) -> DetailWorkoutView {
        let useCase = WorkoutUseCase()

        let viewModel = DetailWorkoutViewModel(useCase: useCase, workout: workout)
        let view = DetailWorkoutView(viewModel: viewModel)
        return view
    }
}
