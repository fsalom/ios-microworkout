//
//  ExerciseUseCaseProtocol.swift
//  microworkout
//
//  Created by Fernando Salom Carratala on 20/7/25.
//

protocol LoggedExerciseUseCaseProtocol {
    func add(this exercise: LoggedExercise) async throws
    func getAll(for id: String) async throws -> [LoggedExercise]
}
