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
    var completed: Float {
        var numberOfSeriesCompleted: Float = 0
        var numberOfSeries: Float = 0
        workouts.forEach { workout in
            numberOfSeries += Float(workout.numberOfSeries)
            numberOfSeriesCompleted += Float(workout.results.count)
        }
        return Float(numberOfSeriesCompleted / numberOfSeries)
    }
    var workouts: [Workout] = []
}
