import Foundation

/// Sube al servidor (bajo el usuario autenticado) los datos que se hayan ido
/// guardando en local como invitado: entrenamientos, sesiones, logs, ejercicios
/// y comidas. Idempotente por UUID en el backend, así que puede reintentarse.
protocol UploadLocalDataUseCaseProtocol {
    func upload() async throws -> Int
}

final class UploadLocalDataUseCase: UploadLocalDataUseCaseProtocol {
    private let training: TrainingRepositoryProtocol
    private let workoutLog: WorkoutLogRepositoryProtocol
    private let exercise: ExerciseRepositoryProtocol
    private let meal: MealRepositoryProtocol

    init(training: TrainingRepositoryProtocol,
         workoutLog: WorkoutLogRepositoryProtocol,
         exercise: ExerciseRepositoryProtocol,
         meal: MealRepositoryProtocol) {
        self.training = training
        self.workoutLog = workoutLog
        self.exercise = exercise
        self.meal = meal
    }

    /// Devuelve el número total de elementos subidos.
    func upload() async throws -> Int {
        var total = 0
        total += try await exercise.uploadLocalToRemote()   // primero: los logs referencian ejercicios
        total += try await training.uploadLocalToRemote()
        total += try await workoutLog.uploadLocalToRemote()
        total += try await meal.uploadLocalToRemote()
        return total
    }
}
