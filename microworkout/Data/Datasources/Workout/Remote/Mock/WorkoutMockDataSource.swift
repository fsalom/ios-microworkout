//
//  WorkoutCoreDataSource.swift
//  microworkout
//
//  Created by Fernando Salom Carratala on 7/6/23.
//

import Foundation

class WorkoutMockDataSource: WorkoutRemoteDataSourceProtocol {
    func getWorkoutPlan() -> WorkoutPlanDTO {
        let workouts = [
            WorkoutDTO(id: "1",
                       exercise: ExerciseDTO(name: "Sentadillas",
                                             type: "rpes"),
                       numberOfSeries: 10,
                       results: [],
                       set: WorkoutSetDTO(id: "1",
                                          exercise: "rpes",
                                          kcal: 0))]
        return WorkoutPlanDTO(id: "1", name: "Lunes", workouts: workouts)
    }
}
