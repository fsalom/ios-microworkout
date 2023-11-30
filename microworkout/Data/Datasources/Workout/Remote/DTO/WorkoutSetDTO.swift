//
//  WorkoutSetDTO.swift
//  microworkout
//
//  Created by Fernando Salom Carratala on 30/11/23.
//

import Foundation

struct WorkoutSetDTO: Codable {
    var id: String
    var exercise: String
    var reps: Int = 0
    var weight: Float = 0.0
    var rpe: Float = 0.0
    var rir: Float = 0.0
    var distance: Int = 0
    var kcal: Int = 0
}
