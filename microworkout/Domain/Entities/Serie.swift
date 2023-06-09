//
//  Serie.swift
//  microworkout
//
//  Created by Fernando Salom Carratala on 7/6/23.
//

import Foundation

struct Serie {
    var reps: Int = 0
    var weight: Float = 0.0
    var rpe: Float = 0.0
    var rir: Float = 0.0
    var distance: Float = 0.0
    var kcal: Int = 0

    init(reps: Int, weight: Float, rpe: Float, rir: Float){
        self.reps = reps
        self.weight = weight
        self.rpe = rpe
        self.rir = rir
    }

    init(reps: Int, distance: Float){
        self.reps = reps
        self.distance = distance
    }
}
