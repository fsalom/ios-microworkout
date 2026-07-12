import Foundation

/// Dispatches per-call to local or remote depending on auth state.
/// Guest → UserDefaults (current behaviour, fully offline).
/// Authenticated → backend at /v1/trainings.
final class TrainingRepository: TrainingRepositoryProtocol {
    private let local: TrainingLocalDataSourceProtocol
    private let remote: TrainingRemoteDataSourceProtocol

    init(
        local: TrainingLocalDataSourceProtocol,
        remote: TrainingRemoteDataSourceProtocol
    ) {
        self.local = local
        self.remote = remote
    }

    private func isAuthenticated() async -> Bool {
        await MainActor.run { AuthSession.shared.state.isAuthenticated }
    }

    /// Hardcoded preset templates. Same list for guest and auth — auth users
    /// can additionally create their own server-side trainings via `saveCurrent`.
    private var presets: [Training] {
        [
            Training(name: "Flexiones", image: "push-up-1", type: .strength, numberOfSetsForSlider: 10, numberOfRepsForSlider: 10, numberOfMinutesPerSetForSlider: 1),
            Training(name: "Dominadas", image: "pull-up-1", type: .strength, numberOfSetsForSlider: 10, numberOfRepsForSlider: 5, numberOfMinutesPerSetForSlider: 60),
            Training(name: "Sentadillas", image: "squat-1", type: .strength, numberOfSetsForSlider: 10, numberOfRepsForSlider: 20, numberOfMinutesPerSetForSlider: 60),
            Training(name: "Abdominales", image: "abs-1", type: .strength, numberOfSetsForSlider: 10, numberOfRepsForSlider: 20, numberOfMinutesPerSetForSlider: 60)
        ]
    }

    func getTrainings() async throws -> [Training] {
        if await isAuthenticated() {
            let remoteTrainings = try await remote.list().map { $0.toDomain() }
            // Show presets first, then user-created (de-duplicated by id).
            let presetIds = Set(presets.map { $0.id })
            let extras = remoteTrainings.filter { !presetIds.contains($0.id) }
            return presets + extras
        }
        return presets
    }

    func getCurrent() async throws -> Training? {
        if await isAuthenticated() {
            return try await remote.current()?.toDomain()
        }
        return local.getCurrent()?.toDomain()
    }

    func saveCurrent(_ training: Training) async throws {
        if await isAuthenticated() {
            _ = try await remote.saveCurrent(training)
            return
        }
        local.saveCurrent(training.toDTO())
    }

    func finish(_ training: Training) async throws {
        if await isAuthenticated() {
            _ = try await remote.finish(training)
            return
        }
        local.finish(training.toDTO())
    }

    func getFinished() async throws -> [Training] {
        if await isAuthenticated() {
            return try await remote.listFinished().map { $0.toDomain() }
        }
        return local.getFinished().map { $0.toDomain() }
    }

    func uploadLocalToRemote() async throws -> Int {
        var count = 0
        if let current = local.getCurrent() {
            _ = try await remote.saveCurrent(current.toDomain())
            local.clearCurrent(); count += 1
        }
        let finished = local.getFinished()
        for dto in finished {
            _ = try await remote.finish(dto.toDomain()); count += 1
        }
        if !finished.isEmpty { local.clearFinished() }   // borrar tras subir: evita duplicar al re-subir
        return count
    }
}

fileprivate extension TrainingDTO {
    func toDomain() -> Training {
        return Training(name: self.name,
                        image: self.image,
                        type: TrainingType(rawValue: self.type) ?? .strength,
                        startedAt: self.startedAt,
                        completedAt: self.completedAt,
                        sets: self.sets,
                        numberOfSetsForSlider: self.numberOfSets,
                        numberOfRepsForSlider: self.numberOfReps,
                        numberOfMinutesPerSetForSlider: self.numberOfMinutesPerSet)
    }
}

fileprivate extension Training {
    func toDTO() -> TrainingDTO {
        return TrainingDTO(
            id: self.id,
            name: self.name,
            image: self.image,
            type: self.type.rawValue,
            startedAt: self.startedAt,
            completedAt: self.completedAt,
            sets: self.sets,
            numberOfSetsCompleted: self.numberOfSetsCompleted,
            numberOfSets: self.numberOfSetsForSlider,
            numberOfReps: self.numberOfRepsForSlider,
            numberOfMinutesPerSet: self.numberOfMinutesPerSetForSlider
        )
    }
}
