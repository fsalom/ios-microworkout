//
//  WorkoutPlanDTO.swift
//  microworkout
//
//  Created by Fernando Salom Carratala on 30/11/23.
//

import Foundation

struct WorkoutPlanDTO: Codable {
    let id: String
    let name: String
    var workouts: [WorkoutDTO] = []
}
