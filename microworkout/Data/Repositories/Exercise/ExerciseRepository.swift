//
//  ExerciseRepository.swift
//  microworkout
//
//  Created by Fernando Salom Carratala on 20/7/25.
//

class ExerciseRepository: ExerciseRepositoryProtocol {
    private var dataSource: ExerciseDataSourceProtocol

    init(dataSource: ExerciseDataSourceProtocol){
        self.dataSource = dataSource
    }

    func getExercises(contains searchText: String) async throws -> [Exercise] {
        try await dataSource.getExercises(contains: searchText).map { $0.toDomain() }
    }

    func getExercises() async throws -> [Exercise] {
        try await dataSource.getExercises().map { $0.toDomain() }
    }
}

fileprivate extension ExerciseDTO {
    func toDomain() -> Exercise {
        return Exercise(name: self.name)
    }
}

fileprivate extension Exercise {
    func toDTO(type: String = "") -> ExerciseDTO {
        return ExerciseDTO(name: self.name, type: type)
    }
}
