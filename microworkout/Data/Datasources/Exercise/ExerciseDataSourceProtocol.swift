//
//  TrainingLocalDataSourceProtocol.swift
//  microworkout
//
//  Created by Fernando Salom Carratala on 20/7/25.
//


protocol ExerciseDataSourceProtocol {
    func getExercises() async throws -> [ExerciseDTO]
    func getExercises(contains searchText: String) async throws -> [ExerciseDTO]
}
