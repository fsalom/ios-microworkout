//
//  DetailWorkoutViewModel.swift
//  microworkout
//
//  Created by Fernando Salom Carratala on 6/7/23.
//

import Foundation

class DetailWorkoutViewModel: ObservableObject {
    @Published var workout: WorkoutPlan

    var useCase: WorkoutUseCaseProtocol!

    init(useCase: WorkoutUseCaseProtocol, workout: WorkoutPlan) {
        self.useCase = useCase
        self.workout = workout
    }

    func load() {
        Task {
            
        }
    }
}
