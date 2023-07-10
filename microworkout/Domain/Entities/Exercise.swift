//
//  Exercise.swift
//  microworkout
//
//  Created by Fernando Salom Carratala on 7/6/23.
//

import Foundation

enum ExerciseType {
    case distance
    case weight
    case kcal
    case reps
}

struct Exercise {
    let name: String
    var type: ExerciseType
}
