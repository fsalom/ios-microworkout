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
            let synced = try await remote.list(contains: searchText).map { $0.toDomain() }
            let localOnly = try await onlyLocal(
                local.getExercises(contains: searchText).map { $0.toDomain() }, notIn: synced)
            return synced + localOnly
        }
        return try await local.getExercises(contains: searchText).map { $0.toDomain() }
    }

    func getExercises() async throws -> [Exercise] {
        if await isAuthenticated() {
            let synced = try await remote.list(contains: nil).map { $0.toDomain() }
            let localOnly = try await onlyLocal(local.getExercises().map { $0.toDomain() }, notIn: synced)
            return synced + localOnly
        }
        return try await local.getExercises().map { $0.toDomain() }
    }

    /// Ejercicios locales que aún no están en el servidor (dedup por nombre).
    private func onlyLocal(_ locals: [Exercise], notIn synced: [Exercise]) -> [Exercise] {
        let syncedNames = Set(synced.map { $0.name.lowercased() })
        return locals.filter { !syncedNames.contains($0.name.lowercased()) }
    }

    func create(_ exercise: Exercise) async throws -> Exercise {
        if await isAuthenticated() {
            return try await remote.create(name: exercise.name, type: exercise.type).toDomain()
        }
        let dto = try await local.create(exercise.toDTO())
        return dto.toDomain()
    }

    /// Modelo espejo: cuenta los ejercicios locales cuyo nombre no está aún en
    /// la cuenta (dedup por nombre, como en las lecturas). No modifica nada local.
    func pendingSyncCount() async throws -> Int {
        let syncedNames = Set(try await remote.list(contains: nil).map { $0.name.lowercased() })
        return try await local.getExercises()
            .filter { !syncedNames.contains($0.name.lowercased()) }
            .count
    }

    /// Sube los ejercicios locales que aún no existan en la cuenta (por nombre).
    /// Nunca borra la copia local — el dispositivo conserva el respaldo.
    func syncLocalToRemote() async throws -> Int {
        let syncedNames = Set(try await remote.list(contains: nil).map { $0.name.lowercased() })
        var count = 0
        for dto in try await local.getExercises() where !syncedNames.contains(dto.name.lowercased()) {
            let e = dto.toDomain()
            _ = try await remote.create(name: e.name, type: e.type)
            count += 1
        }
        return count
    }

    func delete(_ id: UUID) async throws {
        if await isAuthenticated() {
            try await remote.delete(id)
            // Borrar también en local. El dedup de ejercicios es por nombre, así
            // que una copia local que sobreviva se vuelve a subir en la siguiente
            // sincronización y el ejercicio borrado reaparece.
            try? await local.delete(id.uuidString)
        } else {
            try await local.delete(id.uuidString)
        }
    }
}

fileprivate extension ExerciseDTO {
    func toDomain() -> Exercise {
        let uuid = UUID(uuidString: self.id) ?? UUID()
        let type = ExerciseType(rawValue: self.type) ?? .none
        return Exercise(id: uuid, name: self.name, type: type, source: .local)
    }
}

fileprivate extension Exercise {
    func toDTO() -> ExerciseDTO {
        ExerciseDTO(id: self.id.uuidString, name: self.name, type: self.type.rawValue)
    }
}
