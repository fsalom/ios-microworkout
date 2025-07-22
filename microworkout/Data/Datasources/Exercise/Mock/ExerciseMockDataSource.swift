//
//  ExerciseLocalDataSource.swift
//  microworkout
//
//  Created by Fernando Salom Carratala on 20/7/25.
//


class ExerciseMockDataSource: ExerciseDataSourceProtocol {
    let exercises: [ExerciseDTO] = [
        ExerciseDTO(name: "Press de banca", type: "empuje"),
        ExerciseDTO(name: "Sentadilla", type: "pierna"),
        ExerciseDTO(name: "Peso muerto", type: "pierna"),
        ExerciseDTO(name: "Dominadas", type: "tirón"),
        ExerciseDTO(name: "Press militar", type: "empuje"),
        ExerciseDTO(name: "Curl de bíceps", type: "tirón"),
        ExerciseDTO(name: "Remo con barra", type: "tirón")
    ]

    func getExercises(contains searchText: String) async throws -> [ExerciseDTO] {
        return exercises
    }

    func getExercises() async throws -> [ExerciseDTO] {
        return exercises
    }
}
