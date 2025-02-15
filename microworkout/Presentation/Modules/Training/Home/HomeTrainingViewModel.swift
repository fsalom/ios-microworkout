//
//  HomeViewModel.swift
//  microworkout
//
//  Created by Fernando Salom Carratala on 8/6/23.
//

import Foundation
import HealthKit

class HomeTrainingViewModel: ObservableObject, HomeTrainingViewModelProtocol {
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
}
