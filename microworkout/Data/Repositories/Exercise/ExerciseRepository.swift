import Foundation

/// Same auth-aware dispatch as `TrainingRepository`: local catalog in guest mode,
/// backend `/v1/exercises` once the user is logged in.
final class ExerciseRepository: ExerciseRepositoryProtocol {
    private let local: ExerciseDataSourceProtocol
    private let remote: ExerciseRemoteDataSourceProtocol

    init(
        local: ExerciseDataSourceProtocol,
        remote: ExerciseRemoteDataSourceProtocol
    ) {
        self.local = local
        self.remote = remote
    }

    private func isAuthenticated() async -> Bool {
        await MainActor.run { AuthSession.shared.state.isAuthenticated }
    }

    func getExercises(contains searchText: String) async throws -> [Exercise] {
        if await isAuthenticated() {
            return try await remote.list(contains: searchText).map { $0.toDomain() }
        }
        return try await local.getExercises(contains: searchText).map { $0.toDomain() }
    }

    func getExercises() async throws -> [Exercise] {
        if await isAuthenticated() {
            return try await remote.list(contains: nil).map { $0.toDomain() }
        }
        return try await local.getExercises().map { $0.toDomain() }
    }

    func create(_ exercise: Exercise) async throws -> Exercise {
        if await isAuthenticated() {
            return try await remote.create(name: exercise.name, type: exercise.type).toDomain()
        }
        let dto = try await local.create(exercise.toDTO())
        return dto.toDomain()
    }

    func delete(_ id: UUID) async throws {
        if await isAuthenticated() {
            try await remote.delete(id)
        } else {
            try await local.delete(id.uuidString)
        }
    }
}

fileprivate extension ExerciseDTO {
    func toDomain() -> Exercise {
        let uuid = UUID(uuidString: self.id) ?? UUID()
        let type = ExerciseType(rawValue: self.type) ?? .none
        return Exercise(id: uuid, name: self.name, type: type)
    }
}

fileprivate extension Exercise {
    func toDTO() -> ExerciseDTO {
        ExerciseDTO(id: self.id.uuidString, name: self.name, type: self.type.rawValue)
    }
}
