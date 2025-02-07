//
//  DetailWorkoutViewModel.swift
//  gymwatch Watch App
//
//  Created by Fernando Salom Carratala on 31/7/23.
//

import Foundation

class DetailWorkoutViewModel: ObservableObject {
    @Published var workout: WorkoutPlan

    var useCase: WorkoutUseCaseProtocol!

    init(useCase: WorkoutUseCaseProtocol, workout: WorkoutPlan) {
        self.useCase = useCase
        self.workout = workout
    }
}
