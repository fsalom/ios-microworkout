//
//  Planning.swift
//  microworkout
//
//  Created by Fernando Salom Carratala on 7/6/23.
//

import Foundation

struct WorkoutPlan: Identifiable {
    let id: String
    let name: String
    let workout: [Workout]
}
