import Foundation

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
        // Convert stored String ID to UUID, defaulting to new UUID on failure
        let uuid = UUID(uuidString: self.id) ?? UUID()
        let type = ExerciseType(rawValue: self.type) ?? .none
        return Exercise(id: uuid, name: self.name, type: type)
    }
}

fileprivate extension Exercise {
    func toDTO(type: String = "") -> ExerciseDTO {
        return ExerciseDTO(id: self.id.uuidString, name: self.name, type: type)
    }
}
