//
//  ExerciseUseCaseProtocol.swift
//  microworkout
//
//  Created by Fernando Salom Carratala on 20/7/25.
//

protocol ExerciseUseCaseProtocol {
    func getExercises(contains searchText: String) async throws -> [Exercise]
}
