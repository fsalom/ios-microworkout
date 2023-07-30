//
//  ListPlanViewModel.swift
//  gymwatch Watch App
//
//  Created by Fernando Salom Carratala on 30/7/23.
//

import Foundation

class ListPlanViewModel: ObservableObject {
    @Published var workouts: [WorkoutPlan]

    var useCase: WorkoutUseCaseProtocol!

    init(useCase: WorkoutUseCaseProtocol) {
        self.useCase = useCase
        self.workouts = []
    }

    func load() async {
        do {
            let workouts = try await useCase.getWorkouts()
            
            await MainActor.run {
                self.workouts = workouts
            }
        } catch {

        }
    }
}
