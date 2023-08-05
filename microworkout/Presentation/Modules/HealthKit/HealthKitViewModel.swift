//
//  HealthKitViewModel.swift
//  microworkout
//
//  Created by Fernando Salom Carratala on 5/8/23.
//

import Foundation

class HealthKitViewModel: ObservableObject, HealthKitViewModelProtocol {
    @Published var workouts: [WorkoutPlan]

    var useCase: WorkoutUseCaseProtocol!

    init(useCase: WorkoutUseCaseProtocol) {
        self.useCase = useCase
        self.workouts = []
    }

    func load() {
        Task {
            let workouts = try await useCase.getWorkouts()

            await MainActor.run {
                self.workouts = workouts
            }
        }
    }

    func accessHealthInfo() {
        
    }
}
