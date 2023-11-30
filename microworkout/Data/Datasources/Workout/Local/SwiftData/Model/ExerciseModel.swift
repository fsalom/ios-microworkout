//
//  ExerciseModel.swift
//  microworkout
//
//  Created by Fernando Salom Carratala on 30/11/23.
//

import Foundation
import SwiftData

@Model
class ExerciseModel {
    @Attribute(.unique) var id: UUID
    @Attribute var workout: WorkoutModel?
    var summary: String?

    init(id: UUID, workout: WorkoutModel? = nil, summary: String? = nil) {
        self.id = id
        self.workout = workout
        self.summary = summary
    }
}
