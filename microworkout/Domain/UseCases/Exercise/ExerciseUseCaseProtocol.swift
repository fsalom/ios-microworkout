//
//  ExerciseUseCaseProtocol.swift
//  microworkout
//
//  Created by Fernando Salom Carratala on 20/7/25.
//

protocol ExerciseUseCaseProtocol {
    func getAll(contains searchText: String) async throws -> [Exercise]
    func create(with name: String) async throws -> Exercise
}
