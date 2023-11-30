//
//  WorkoutDTO.swift
//  microworkout
//
//  Created by Fernando Salom Carratala on 30/11/23.
//

import Foundation

struct WorkoutDTO: Codable {
    let id: String
    var exercise: ExerciseDTO
    let numberOfSeries: Int
    var results: [WorkoutSetDTO]
    var set: WorkoutSetDTO
}
