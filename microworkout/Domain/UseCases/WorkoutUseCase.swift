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
        return [WorkoutPlan(id: "1",
                            name: "Pierna",
                            workouts: [Workout(name: "Sentadilla"),
                                       Workout(name: "Press banca"),
                                       Workout(name: "Peso muerto")]),
                WorkoutPlan(id: "2",
                            name: "Pecho + Biceps",
                            workouts: [Workout(name: "Press Militar")]),
                WorkoutPlan(id: "3",
                            name: "Espalda + Triceps",
                            workouts: [Workout(name: "Zancadas")]),
                WorkoutPlan(id: "4",
                            name: "Accesorios",
                            workouts: [Workout()])]
    }
}
