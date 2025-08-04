//
//  ExerciseUseCaseProtocol.swift
//  microworkout
//
//  Created by Fernando Salom Carratala on 20/7/25.
//

import Foundation

protocol LoggedExerciseUseCaseProtocol {
    func add(new exercise: LoggedExercise) async throws -> [LoggedExercise]
    func update(this exercise: LoggedExercise) async throws -> [LoggedExercise]
    func delete(this id: String) async throws -> [LoggedExercise]
    func getAll() async throws -> [LoggedExerciseByDay]
    func groupByExercise(these exercises: [LoggedExercise]) -> [Exercise: [LoggedExercise]]
    func order(these exercises: [LoggedExercise]) -> [Exercise]
    func save(these exercises: [LoggedExercise], with duration: Int) async throws
}
