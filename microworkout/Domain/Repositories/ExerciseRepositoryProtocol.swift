//
//  ExerciseRepositoryProtocol.swift
//  microworkout
//
//  Created by Fernando Salom Carratala on 20/7/25.
//

protocol ExerciseRepositoryProtocol {
    func getExercises(contains searchText: String) async throws -> [Exercise]
    func getExercises() async throws -> [Exercise]
}
