//
//  WorkoutUseCase.swift
//  microworkout
//
//  Created by Fernando Salom Carratala on 6/6/23.
//

import Foundation

protocol WorkoutUseCaseProtocol {
    func getWorkouts() async throws -> [WorkoutPlan]
}


class WorkoutUseCase: WorkoutUseCaseProtocol {
    func getWorkouts() async throws -> [WorkoutPlan] {
        return [WorkoutPlan(id: "", name: "ejemplo", workout: [])]
    }
}
