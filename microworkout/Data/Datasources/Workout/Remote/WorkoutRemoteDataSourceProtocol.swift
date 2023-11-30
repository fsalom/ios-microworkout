//
//  WorkoutRemoteDataSource.swift
//  microworkout
//
//  Created by Fernando Salom Carratala on 30/11/23.
//

import Foundation

protocol WorkoutRemoteDataSourceProtocol {
    func getWorkoutPlan() -> WorkoutPlanDTO
}
