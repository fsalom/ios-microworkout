//
//  Workout.swift
//  microworkout
//
//  Created by Fernando Salom Carratala on 6/6/23.
//

import Foundation

struct Workout: Identifiable {
    let id: String = UUID().uuidString
    var exercise: Exercise
    let numberOfSeries: Int
    var results: [Serie]
    let serie: Serie
    var isCollapsed: Bool = true

    init(name: String) {
        exercise = .init(name: name, type: .weight)
        numberOfSeries = 4
        results = [Serie(reps: 10, weight: 81.25, rpe: 8.0, rir: 9.0),
                   Serie(reps: 10, weight: 85.0, rpe: 8.0, rir: 9.0),
                   Serie(reps: 10, weight: 82.5, rpe: 8.0, rir: 9.0)]
        serie =  Serie(reps: 10, weight: 80.0, rpe: 8.0, rir: 9.0)
    }

    init() {
        self.exercise = .init(name: "Correr", type: .none)
        numberOfSeries = 4
        results = []
        serie =  Serie()
    }
}
