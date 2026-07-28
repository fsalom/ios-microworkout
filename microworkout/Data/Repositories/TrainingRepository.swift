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
    ///
    /// `static let`, no computed property: `Training.id` tiene por defecto `UUID()`,
    /// así que una propiedad calculada devolvía ids NUEVOS en cada acceso. Eso
    /// rompía todo lo que identifica un entrenamiento por id — el dedup de
    /// `getTrainings()` no casaba nunca (los presets subidos salían duplicados), el
    /// enlace de un entreno de Apple Health con `linkedTrainingID` no se resolvía,
    /// la restauración de scroll de la lista fallaba y el Watch recibía ids
    /// distintos en cada arranque.
    ///
    /// Estos UUID son parte del contrato de datos: NO cambiarlos ni reordenarlos.
    private static let presets: [Training] = [
        Training(id: presetID("6E1B4C7A-3F2D-4A18-9B5E-0C7D8A1F4B23"), name: "Flexiones", image: "push-up-1", type: .strength, numberOfSetsForSlider: 10, numberOfRepsForSlider: 10, numberOfMinutesPerSetForSlider: 1),
        Training(id: presetID("B24F9D01-8E5A-4C36-A7F1-2D9E6B0C3A57"), name: "Dominadas", image: "pull-up-1", type: .strength, numberOfSetsForSlider: 10, numberOfRepsForSlider: 5, numberOfMinutesPerSetForSlider: 60),
        Training(id: presetID("0A7C5E92-1D6B-4F80-83A4-5C2E9F1B7D46"), name: "Sentadillas", image: "squat-1", type: .strength, numberOfSetsForSlider: 10, numberOfRepsForSlider: 20, numberOfMinutesPerSetForSlider: 60),
        Training(id: presetID("D95E3A16-7B4C-42F9-8E01-6A3D2C8F5B70"), name: "Abdominales", image: "abs-1", type: .strength, numberOfSetsForSlider: 10, numberOfRepsForSlider: 20, numberOfMinutesPerSetForSlider: 60)
    ]

    /// Las cadenas de arriba son constantes válidas; el fallback existe solo para
    /// no forzar un unwrap y nunca se ejecuta.
    private static func presetID(_ value: String) -> UUID {
        UUID(uuidString: value) ?? UUID()
    }

    func getTrainings() async throws -> [Training] {
        let presets = Self.presets
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

    /// Modelo espejo: cuenta los entrenamientos locales cuyo id no está aún en
    /// la cuenta. No modifica nada local.
    func pendingSyncCount() async throws -> Int {
        let remoteIds = Set(try await remote.list().map { $0.id })
        var pending = 0
        if let current = local.getCurrent(), !remoteIds.contains(current.id) { pending += 1 }
        pending += local.getFinished().filter { !remoteIds.contains($0.id) }.count
        return pending
    }

    /// Sube los entrenamientos locales que aún no estén en la cuenta (por id).
    /// Nunca borra la copia local — el dispositivo conserva el respaldo.
    func syncLocalToRemote() async throws -> Int {
        let remoteIds = Set(try await remote.list().map { $0.id })
        var count = 0
        if let current = local.getCurrent(), !remoteIds.contains(current.id) {
            _ = try await remote.saveCurrent(current.toDomain()); count += 1
        }
        for dto in local.getFinished() where !remoteIds.contains(dto.id) {
            _ = try await remote.finish(dto.toDomain()); count += 1
        }
        return count
    }
}

fileprivate extension TrainingDTO {
    func toDomain() -> Training {
        return Training(id: self.id,
                        name: self.name,
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
