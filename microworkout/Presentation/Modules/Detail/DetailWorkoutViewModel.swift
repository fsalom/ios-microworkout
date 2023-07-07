//
//  DetailWorkoutViewModel.swift
//  microworkout
//
//  Created by Fernando Salom Carratala on 6/7/23.
//

import Foundation

class DetailWorkoutViewModel: ObservableObject {
    @Published var plan: WorkoutPlan

    var useCase: WorkoutUseCaseProtocol!

    init(useCase: WorkoutUseCaseProtocol, plan: WorkoutPlan) {
        self.useCase = useCase
        self.plan = plan
    }

    func load() {
        Task {
            
        }
    }
}
