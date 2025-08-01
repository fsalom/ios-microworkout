//
//  ExerciseLocalDataSource.swift
//  microworkout
//
//  Created by Fernando Salom Carratala on 20/7/25.
//


class ExerciseMockDataSource: ExerciseDataSourceProtocol {
    let exercises: [ExerciseDTO] = [
        ExerciseDTO(id: "press-de-banca", name: "Press de banca", type: "empuje"),
        ExerciseDTO(id: "sentadilla", name: "Sentadilla", type: "pierna"),
        ExerciseDTO(id: "peso-muerto", name: "Peso muerto", type: "pierna"),
        ExerciseDTO(id: "dominadas", name: "Dominadas", type: "tirón"),
        ExerciseDTO(id: "press-militar", name: "Press militar", type: "empuje"),
        ExerciseDTO(id: "curl-de-biceps", name: "Curl de bíceps", type: "tirón"),
        ExerciseDTO(id: "remo-con-barra", name: "Remo con barra", type: "tirón")
    ]

    func getExercises(contains searchText: String) async throws -> [ExerciseDTO] {
        return exercises
    }

    func getExercises() async throws -> [ExerciseDTO] {
        return exercises
    }
}
