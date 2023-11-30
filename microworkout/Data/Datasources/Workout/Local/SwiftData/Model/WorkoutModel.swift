//
//  WorkoutModel.swift
//  microworkout
//
//  Created by Fernando Salom Carratala on 30/11/23.
//

import Foundation
import SwiftData

@Model
class WorkoutModel {
    @Attribute(.unique) var id: UUID
    @Relationship(inverse: \ExerciseModel.workout) var exercises: [ExerciseModel]
    @Attribute var workoutPlan: WorkoutPlanModel?

    init(id: UUID, exercises: [ExerciseModel], workoutPlan: WorkoutPlanModel? = nil) {
        self.id = id
        self.exercises = exercises
        self.workoutPlan = workoutPlan
    }
}
