//
//  Workout.swift
//  microworkout
//
//  Created by Fernando Salom Carratala on 6/6/23.
//

import Foundation

struct Workout: Identifiable {
    let id: String = UUID().uuidString
    let exercise: Exercise
    let numberOfSeries: Int
    let results: [Serie]
    let serie: Serie
}
