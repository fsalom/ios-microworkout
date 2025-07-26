//
//  ExerciseUseCaseProtocol.swift
//  microworkout
//
//  Created by Fernando Salom Carratala on 20/7/25.
//

import Foundation

protocol LoggedExerciseUseCaseProtocol {
    func add(new exercise: LoggedExercise) async throws
    func update(this exercise: LoggedExercise)
    func delete(with ids: [UUID])
    func getAll(for id: String) async throws -> [LoggedExercise]
    func groupByExercise(these exercises: [LoggedExercise]) -> [Exercise: [LoggedExercise]]
    func order(these exercises: [LoggedExercise]) -> [Exercise]
}
