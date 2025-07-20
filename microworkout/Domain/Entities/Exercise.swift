//
//  Exercise.swift
//  microworkout
//
//  Created by Fernando Salom Carratala on 7/6/23.
//

import Foundation

enum ExerciseType: CaseIterable, Identifiable {
    case distance
    case weight
    case kcal
    case reps
    case none

    var id: Self { self }
}

struct Exercise: Identifiable, Hashable {
    let id = UUID()
    let name: String
    var type: ExerciseType = .weight
}
