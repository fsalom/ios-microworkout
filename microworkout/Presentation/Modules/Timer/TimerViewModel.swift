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
    var progression: Float

    init(useCase: WorkoutUseCaseProtocol, workout: Workout, seconds: Int) {
        self.useCase = useCase
        self.workout = workout
        self.progression = Float(seconds / 100)
    }

    func setRestTime() {
        
    }

    func load() {
        Task {

        }
    }
}
