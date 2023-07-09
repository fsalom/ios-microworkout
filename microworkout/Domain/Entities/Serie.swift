//
//  Serie.swift
//  microworkout
//
//  Created by Fernando Salom Carratala on 7/6/23.
//

import Foundation

struct Serie: Identifiable {
    var id: String = UUID().uuidString
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

extension Float {
    var formatted: String {
        return self.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", self) : String(self)
    }
}
