//
//  WorkoutPlanModel.swift
//  microworkout
//
//  Created by Fernando Salom Carratala on 30/11/23.
//

import Foundation
import SwiftData

@Model
class WorkoutPlanModel {
    @Attribute(.unique) var id: UUID
    let name: String
    @Relationship(inverse: \WorkoutModel.workoutPlan) var workouts: [WorkoutModel]


    init(id: UUID, name: String, workouts: [WorkoutModel]) {
        self.id = id
        self.name = name
        self.workouts = workouts
    }
}
