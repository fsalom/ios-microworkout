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
    var totalNumberOfSeries: Int {
        var total = 0
        for workout in workouts {
            total += workout.numberOfSeries
        }
        return total
    }
    var workouts: [Workout] = []
}
