import Foundation

// MARK: - Modelo de sincronización

/// Categorías de datos que la app puede sincronizar con la cuenta.
/// El orden de `allCases` es también el orden en que se sincronizan
/// (perfil y ejercicios primero, porque logs y sesiones los referencian).
enum SyncCategory: String, CaseIterable, Identifiable {
    case profile
    case exercises
    case trainings
    case workoutLogs
    case meals
    case bodyMetrics

    var id: String { rawValue }

    var title: String {
        switch self {
        case .profile:     return "Perfil"
        case .exercises:   return "Ejercicios"
        case .trainings:   return "Entrenamientos"
        case .workoutLogs: return "Sesiones y registros"
        // Esta categoría cubre comidas, recetas y alimentos favoritos.
        case .meals:       return "Comidas y alimentos"
        case .bodyMetrics: return "Peso"
        }
    }

    var icon: String {
        switch self {
        case .profile:     return "person.crop.circle"
        case .exercises:   return "dumbbell"
        case .trainings:   return "figure.strengthtraining.traditional"
        case .workoutLogs: return "list.bullet.clipboard"
        case .meals:       return "fork.knife"
        case .bodyMetrics: return "scalemass"
        }
    }
}

/// Estado de sincronización de una categoría en un momento dado.
struct SyncCategoryStatus: Identifiable {
    let category: SyncCategory
    /// Elementos que están en local pero todavía NO en la cuenta.
    var pending: Int
    /// Elementos subidos en la última sincronización manual (`nil` si aún no se
    /// ha ejecutado una desde que se abrió la pantalla).
    var uploaded: Int?
    /// Mensaje legible si no se pudo comprobar o subir esta categoría.
    var error: String?

    var id: String { category.id }

    /// Verde: todo lo local está también en la cuenta.
    var isSynced: Bool { error == nil && pending == 0 }
}

/// Informe global que consume la UI del perfil.
struct SyncReport {
    var statuses: [SyncCategoryStatus]

    var totalPending: Int { statuses.reduce(0) { $0 + $1.pending } }
    var totalUploaded: Int { statuses.reduce(0) { $0 + ($1.uploaded ?? 0) } }
    var hasErrors: Bool { statuses.contains { $0.error != nil } }
    var isFullySynced: Bool { !hasErrors && totalPending == 0 }

    func status(for category: SyncCategory) -> SyncCategoryStatus? {
        statuses.first { $0.category == category }
    }

    /// Informe inicial "en blanco" (sin pendientes conocidos, sin errores) para
    /// mostrar la pantalla antes de la primera comprobación contra el servidor.
    static func empty() -> SyncReport {
        SyncReport(statuses: SyncCategory.allCases.map {
            SyncCategoryStatus(category: $0, pending: 0, uploaded: nil, error: nil)
        })
    }
}

// MARK: - Caso de uso

/// Sincroniza (modelo espejo) los datos locales con la cuenta: garantiza que
/// todo lo que está en el dispositivo esté también en el servidor, SIN borrar
/// nunca la copia local — el dispositivo conserva siempre un respaldo.
///
/// - `status()` solo comprueba qué falta por subir (no escribe nada).
/// - `sync()` sube lo que falta y devuelve el resultado por categoría.
///
/// Ambas operaciones son resilientes: cada categoría se procesa de forma
/// independiente, así que un fallo en una (p. ej. de red) no impide sincronizar
/// las demás. Es idempotente por id/nombre en el backend, se puede reintentar.
protocol SyncLocalDataUseCaseProtocol {
    /// Comprueba, categoría a categoría, cuántos elementos locales faltan por
    /// subir. No modifica nada. Requiere estar autenticado.
    func status() async -> SyncReport

    /// Sube lo pendiente de cada categoría y devuelve el informe resultante
    /// (subidos + lo que quede pendiente + errores por categoría).
    ///
    /// - Parameter progress: se invoca al empezar cada categoría, para que la UI
    ///   pueda decir qué se está subiendo ahora mismo. No se llama en el hilo
    ///   principal; quien lo consuma debe saltar él.
    func sync(progress: ((SyncCategory) -> Void)?) async -> SyncReport
}

extension SyncLocalDataUseCaseProtocol {
    func sync() async -> SyncReport { await sync(progress: nil) }
}

final class SyncLocalDataUseCase: SyncLocalDataUseCaseProtocol {
    private let training: TrainingRepositoryProtocol
    private let workoutLog: WorkoutLogRepositoryProtocol
    private let exercise: ExerciseRepositoryProtocol
    private let meal: MealRepositoryProtocol
    private let userProfile: UserProfileRepositoryProtocol
    private let bodyMetrics: BodyMetricsRepositoryProtocol

    init(training: TrainingRepositoryProtocol,
         workoutLog: WorkoutLogRepositoryProtocol,
         exercise: ExerciseRepositoryProtocol,
         meal: MealRepositoryProtocol,
         userProfile: UserProfileRepositoryProtocol,
         bodyMetrics: BodyMetricsRepositoryProtocol) {
        self.training = training
        self.workoutLog = workoutLog
        self.exercise = exercise
        self.meal = meal
        self.userProfile = userProfile
        self.bodyMetrics = bodyMetrics
    }

    func status() async -> SyncReport {
        var statuses: [SyncCategoryStatus] = []
        for category in SyncCategory.allCases {
            do {
                let pending = try await pendingCount(for: category)
                statuses.append(SyncCategoryStatus(category: category, pending: pending, uploaded: nil, error: nil))
            } catch {
                statuses.append(SyncCategoryStatus(category: category, pending: 0, uploaded: nil, error: Self.message(for: error)))
            }
        }
        return SyncReport(statuses: statuses)
    }

    func sync(progress: ((SyncCategory) -> Void)? = nil) async -> SyncReport {
        var statuses: [SyncCategoryStatus] = []
        for category in SyncCategory.allCases {
            progress?(category)
            do {
                let uploaded = try await upload(for: category)
                // Recalcular lo pendiente tras subir para que el contador sea fiel.
                let remaining = try await pendingCount(for: category)
                statuses.append(SyncCategoryStatus(category: category, pending: remaining, uploaded: uploaded, error: nil))
            } catch {
                statuses.append(SyncCategoryStatus(category: category, pending: 0, uploaded: nil, error: Self.message(for: error)))
            }
        }
        return SyncReport(statuses: statuses)
    }

    // MARK: - Despacho por categoría

    private func pendingCount(for category: SyncCategory) async throws -> Int {
        switch category {
        case .profile:     return try await userProfile.pendingSyncCount()
        case .exercises:   return try await exercise.pendingSyncCount()
        case .trainings:   return try await training.pendingSyncCount()
        case .workoutLogs: return try await workoutLog.pendingSyncCount()
        case .meals:       return try await meal.pendingSyncCount()
        case .bodyMetrics: return try await bodyMetrics.pendingSyncCount()
        }
    }

    private func upload(for category: SyncCategory) async throws -> Int {
        switch category {
        case .profile:     return try await userProfile.syncLocalToRemote()
        case .exercises:   return try await exercise.syncLocalToRemote()
        case .trainings:   return try await training.syncLocalToRemote()
        case .workoutLogs: return try await workoutLog.syncLocalToRemote()
        case .meals:       return try await meal.syncLocalToRemote()
        case .bodyMetrics: return try await bodyMetrics.syncLocalToRemote()
        }
    }

    /// Traduce un error a un mensaje corto para la UI, sin acoplar el dominio a
    /// los tipos de red de la capa Data.
    private static func message(for error: Error) -> String {
        let ns = error as NSError
        if ns.domain == NSURLErrorDomain { return "Sin conexión" }
        return "No se pudo sincronizar"
    }
}
