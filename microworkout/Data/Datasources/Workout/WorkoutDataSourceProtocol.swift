//
//  WorkoutDataSourceProtocol.swift
//  microworkout
//
//  Created by Fernando Salom Carratala on 7/6/23.
//

import Foundation

protocol WorkoutDataSourceProtocol {
    func create(this: Exercise)
    func create(this: Workout)
    func create(this: WorkoutPlan)
}
