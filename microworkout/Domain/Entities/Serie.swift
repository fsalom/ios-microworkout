//
//  Serie.swift
//  microworkout
//
//  Created by Fernando Salom Carratala on 7/6/23.
//

import Foundation

struct Serie: Identifiable, Hashable {
    var id: String = UUID().uuidString
    var exercise: ExerciseType
    var reps: Int = 0
    var weight: Float = 0.0
    var rpe: Float = 0.0
    var rir: Float = 0.0
    var distance: Int = 0
    var kcal: Int = 0

    init(reps: Int, weight: Float, rpe: Float, rir: Float){
        self.exercise = .weight
        self.reps = reps
        self.weight = weight
        self.rpe = rpe
        self.rir = rir
    }

    init(reps: Int, distance: Int){
        self.exercise = .distance
        self.reps = reps
        self.distance = distance
    }

    init(kcal: Int){
        self.exercise = .kcal
        self.kcal = kcal
    }

    init(reps: Int){
        self.exercise = .reps
        self.reps = reps
    }

    init() {
        self.exercise = .none
    }
}
