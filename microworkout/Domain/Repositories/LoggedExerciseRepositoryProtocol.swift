//
//  ExerciseRepositoryProtocol.swift
//  microworkout
//
//  Created by Fernando Salom Carratala on 20/7/25.
//

protocol LoggedExerciseRepositoryProtocol {
    func add(this exercise: LoggedExercise) async throws -> [LoggedExercise]
    func update(this exercise: LoggedExercise) async throws -> [LoggedExercise]
    func delete(with id: String) async throws -> [LoggedExercise]
    func delete(this loggedExercisesByDay: LoggedExerciseByDay) async throws
    func save(these exercises: [LoggedExercise], with duration: Int) async throws
    func getAll() async throws -> [LoggedExerciseByDay]
}
