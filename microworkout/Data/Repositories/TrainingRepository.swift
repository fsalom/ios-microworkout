import Foundation

/// Dispatches per-call to local or remote depending on auth state.
/// Guest → UserDefaults (current behaviour, fully offline).
/// Authenticated → backend at /v1/trainings.
final class TrainingRepository: TrainingRepositoryProtocol {
    private let local: TrainingLocalDataSourceProtocol
    private let remote: TrainingRemoteDataSourceProtocol

    private let session: AuthStateProviding

    init(
        local: TrainingLocalDataSourceProtocol,
        remote: TrainingRemoteDataSourceProtocol,
        session: AuthStateProviding = SharedAuthState()
    ) {
        self.local = local
        self.remote = remote
        self.session = session
    }

    private func isAuthenticated() async -> Bool {
        await session.isAuthenticated
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
            // Un fallo del servidor degrada al catálogo local en vez de propagarse.
            // Los presets son constantes de la app y no dependen de la red: dejar
            // la pantalla en blanco por una caída, cuando quien llama usa `try?`,
            // esconde hasta lo que sí teníamos.
            let remoteTrainings = (try? await remote.list())?.map { $0.toDomain() } ?? []
            // Show presets first, then user-created (de-duplicated by id).
            let presetIds = Set(presets.map { $0.id })
            let extras = remoteTrainings.filter { !presetIds.contains($0.id) }
            return presets + extras
        }
        return presets
    }

    func getCurrent() async throws -> Training? {
        guard await isAuthenticated() else { return local.getCurrent()?.toDomain() }
        do {
            // `nil` aquí es una RESPUESTA ("no hay ninguno en curso"), no un fallo:
            // no se recurre al local, que puede ser uno ya terminado en otro sitio.
            return try await remote.current()?.toDomain()
        } catch {
            // Sin servidor, el entreno en curso del dispositivo es lo único que hay.
            return local.getCurrent()?.toDomain()
        }
    }

    /// Se guarda SIEMPRE en el dispositivo, tanto como invitado como con sesión: el
    /// entreno en curso es lo que se pierde si la app muere o no hay cobertura, y
    /// con la copia local la sincronización lo sube después (dedup por id).
    func saveCurrent(_ training: Training) async throws {
        local.saveCurrent(training.toDTO())
        guard await isAuthenticated() else { return }
        // Un fallo del servidor no se propaga: ya está guardado en el dispositivo y
        // `pendingSyncCount` lo cuenta como pendiente. Antes se propagaba y, como
        // los llamantes hacen `try?`, no quedaba constancia en ninguna parte.
        _ = try? await remote.saveCurrent(training)
    }

    func finish(_ training: Training) async throws {
        // Igual que `saveCurrent`: el registro de lo entrenado se guarda en el
        // dispositivo pase lo que pase. `local.finish` además limpia el entreno en
        // curso, así que la pantalla queda consistente aunque el servidor falle.
        local.finish(training.toDTO())
        guard await isAuthenticated() else { return }
        _ = try? await remote.finish(training)
    }

    func getFinished() async throws -> [Training] {
        let stored = local.getFinished().map { $0.toDomain() }
        guard await isAuthenticated() else { return stored }

        // Fusión, no reemplazo: devolver solo el servidor hacía desaparecer del
        // historial todo lo entrenado como invitado mientras la subida no hubiera
        // pasado (o hubiera fallado), aunque siguiera en el dispositivo. Un fallo
        // del servidor degrada a local por lo mismo — y aquí importa el doble,
        // porque quien consume esto usa `try?` y se quedaba con la lista vacía.
        let synced = (try? await remote.listFinished())?.map { $0.toDomain() } ?? []
        let syncedKeys = Set(synced.map(Self.instanceKey))
        return (synced + stored.filter { !syncedKeys.contains(Self.instanceKey($0)) })
            .sorted { Self.date(of: $0) > Self.date(of: $1) }
    }

    /// Identidad de UN entreno terminado concreto.
    ///
    /// NO vale el id a secas: al empezar un preset se conserva su UUID, así que
    /// todas las veces que has hecho "Flexiones" comparten id. Deduplicar por id
    /// borraría del historial todas las repeticiones menos una — justo lo que este
    /// método existe para evitar. Lo que distingue una instancia es cuándo se
    /// terminó, redondeado al segundo porque servidor y dispositivo no coinciden en
    /// la fracción.
    private static func instanceKey(_ training: Training) -> String {
        let seconds = (training.completedAt ?? training.startedAt).map { Int($0.timeIntervalSince1970.rounded()) }
        return "\(training.id.uuidString)|\(seconds.map(String.init) ?? "-")"
    }

    private static func date(of training: Training) -> Date {
        training.completedAt ?? training.startedAt ?? .distantPast
    }

    /// Modelo espejo: cuenta lo que este dispositivo tiene y la cuenta no.
    /// No modifica nada local.
    func pendingSyncCount() async throws -> Int {
        let synced = try await syncedState()
        var pending = 0
        if let current = local.getCurrent(), synced.currentId != current.id { pending += 1 }
        pending += local.getFinished()
            .filter { !synced.finishedKeys.contains(Self.instanceKey($0.toDomain())) }
            .count
        return pending
    }

    /// Sube los entrenamientos locales que aún no estén en la cuenta.
    /// Nunca borra la copia local — el dispositivo conserva el respaldo.
    func syncLocalToRemote() async throws -> Int {
        let synced = try await syncedState()
        var count = 0
        if let current = local.getCurrent(), synced.currentId != current.id {
            _ = try await remote.saveCurrent(current.toDomain()); count += 1
        }
        for dto in local.getFinished()
        where !synced.finishedKeys.contains(Self.instanceKey(dto.toDomain())) {
            _ = try await remote.finish(dto.toDomain()); count += 1
        }
        return count
    }

    /// Lo que la cuenta ya tiene, en los mismos términos con los que se compara al
    /// leer: el historial por `instanceKey` y el entreno en curso por id.
    ///
    /// NO se usa `remote.list()` (el catálogo, `status=all`) ni se compara por id
    /// a secas. Con las dos cosas a la vez, la segunda vez que hacías un preset no
    /// subía nunca: su UUID ya estaba en el catálogo desde la primera, así que
    /// `pendingSyncCount` decía 0 y el banner remataba con "Todo estaba ya
    /// sincronizado" mientras esa sesión se quedaba solo en el dispositivo.
    private func syncedState() async throws -> (finishedKeys: Set<String>, currentId: UUID?) {
        async let finished = remote.listFinished()
        async let current = remote.current()
        return (
            finishedKeys: Set(try await finished.map { Self.instanceKey($0.toDomain()) }),
            currentId: try await current?.id
        )
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
