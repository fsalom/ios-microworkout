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
    let id: String
    let name: String
    var type: ExerciseType = .weight
}

extension Exercise {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Exercise, rhs: Exercise) -> Bool {
        return lhs.id == rhs.id
    }
}
