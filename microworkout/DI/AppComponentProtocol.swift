import Foundation

/// Protocolo que expone proveedores y use cases compartidos.
///
/// Las propiedades de use case están pensadas para ser cacheadas por la
/// implementación (una instancia por sesión de app), evitando reconstruir
/// el grafo completo cada vez que un Builder los necesita.
protocol AppComponentProtocol: AnyObject {
    func makeUserDefaultsManager() -> UserDefaultsManagerProtocol
    func makeHealthKitManager() -> HealthKitManagerProtocol

    var mealUseCase: MealUseCase { get }
    var healthUseCase: HealthUseCase { get }
    var workoutLogUseCase: WorkoutLogUseCaseProtocol { get }
    var workoutEntryUseCase: WorkoutEntryUseCase { get }
    var userProfileUseCase: UserProfileUseCase { get }
    var trainingUseCase: TrainingUseCaseProtocol { get }
    var exerciseUseCase: ExerciseUseCase { get }
    var setMediaUseCase: SetMediaUseCase { get }
    var aiContextUseCase: AIContextUseCaseProtocol { get }
    var coachUseCase: CoachUseCaseProtocol { get }
    var exerciseProgressionUseCase: ExerciseProgressionUseCaseProtocol { get }

    var authSession: AuthSession { get }
    var authService: AuthServiceProtocol { get }
}
