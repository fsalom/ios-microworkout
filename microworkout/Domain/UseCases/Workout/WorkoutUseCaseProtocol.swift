//
//  WorkoutUseCaseProtocol.swift
//  microworkout
//
//  Created by Fernando Salom Carratala on 19/11/23.
//

import Foundation

protocol WorkoutUseCaseProtocol {
    func getWorkouts() async throws -> [WorkoutPlan]
}
