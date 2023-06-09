//
//  TimerViewModel.swift
//  microworkout
//
//  Created by Fernando Salom Carratala on 9/6/23.
//

import Foundation

class TimerViewModel: ObservableObject, TimerViewModelProtocol {
    @Published var workout: Workout

    var useCase: WorkoutUseCaseProtocol!

    init(useCase: WorkoutUseCaseProtocol, workout: Workout) {
        self.useCase = useCase
        self.workout = workout
    }

    func load() {
        Task {

        }
    }
}
