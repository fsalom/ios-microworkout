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
        let workout = Workout(exercise: .init(name: "Sentadilla",
                                              type: .reps),
                              numberOfSeries: 4,
                              results: [Serie(reps: 10,
                                              weight: 80.0,
                                              rpe: 8.0,
                                              rir: 9.0)],
                              serie: Serie(reps: 10,
                                           weight: 80.0,
                                           rpe: 8.0,
                                           rir: 9.0))
        let workout1 = Workout(exercise: .init(name: "Sentadilla",
                                              type: .reps),
                              numberOfSeries: 1,
                              results: [Serie(reps: 10,
                                              weight: 80.0,
                                              rpe: 8.0,
                                              rir: 9.0)],
                              serie: Serie(reps: 10,
                                           weight: 80.0,
                                           rpe: 8.0,
                                           rir: 9.0))
        return [WorkoutPlan(id: "1", name: "ejemplo", workouts: [workout, workout, workout]),
                WorkoutPlan(id: "2", name: "ejemplo", workouts: [workout]),
                WorkoutPlan(id: "3", name: "ejemplo", workouts: [workout1]),
                WorkoutPlan(id: "4", name: "ejemplo", workouts: [workout])]
    }
}
