//
//  WorkoutDataSourceProtocol.swift
//  microworkout
//
//  Created by Fernando Salom Carratala on 7/6/23.
//

import Foundation

protocol WorkoutLocalDataSourceProtocol {
    func create(this: ExerciseModel)
    func create(this: WorkoutModel)
    func create(this: WorkoutPlanModel)
}
