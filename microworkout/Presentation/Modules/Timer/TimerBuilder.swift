//
//  TimerBuilder.swift
//  microworkout
//
//  Created by Fernando Salom Carratala on 9/6/23.
//

import Foundation

class TimerBuilder {
    func build(this workout: Workout) -> TimerView<TimerViewModel> {
        let useCase = WorkoutUseCase()

        let viewModel = TimerViewModel(useCase: useCase, workout: workout, seconds: 10)
        let view = TimerView(viewModel: viewModel)
        return view
    }
}
