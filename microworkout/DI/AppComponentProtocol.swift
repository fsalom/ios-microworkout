import Foundation

/// Protocolo que expone proveedores y use cases compartidos.
///
/// Las propiedades de use case están pensadas para ser cacheadas por la
/// implementación (una instancia por sesión de app), evitando reconstruir
/// el grafo completo cada vez que un Builder los necesita.
protocol AppComponentProtocol: AnyObject {
    func makeUserDefaultsManager() -> UserDefaultsManagerProtocol
    func makeHealthKitManager() -> HealthKitManagerProtocol

    // Todos los use cases se exponen por PROTOCOLO, nunca por la clase concreta.
    // Los seis primeros exponían el tipo concreto, y eso es lo que impedía escribir
    // un test de un ViewModel que los recibiera: no había nada que doblar. Los
    // protocolos ya existían; solo faltaba declararlos aquí.
    var mealUseCase: MealUseCaseProtocol { get }
    var healthUseCase: HealthUseCaseProtocol { get }
    var workoutLogUseCase: WorkoutLogUseCaseProtocol { get }
    var workoutEntryUseCase: WorkoutEntryUseCaseProtocol { get }
    var userProfileUseCase: UserProfileUseCaseProtocol { get }
    var trainingUseCase: TrainingUseCaseProtocol { get }
    var exerciseUseCase: ExerciseUseCaseProtocol { get }
    var setMediaUseCase: SetMediaUseCaseProtocol { get }
    var aiContextUseCase: AIContextUseCaseProtocol { get }
    var coachUseCase: CoachUseCaseProtocol { get }
    var coachActionUseCase: CoachActionUseCaseProtocol { get }
    var aiCoachChatUseCase: AICoachChatUseCaseProtocol { get }
    var userReportUseCase: UserReportUseCaseProtocol { get }
    var coachFeedbackUseCase: CoachFeedbackUseCaseProtocol { get }
    var adaptiveTDEEUseCase: AdaptiveTDEEUseCaseProtocol { get }
    var bodyMetricsUseCase: BodyMetricsUseCaseProtocol { get }
    var weeklyPlanUseCase: WeeklyPlanUseCaseProtocol { get }
    var exerciseProgressionUseCase: ExerciseProgressionUseCaseProtocol { get }
    var syncLocalDataUseCase: SyncLocalDataUseCaseProtocol { get }

    var authSession: AuthSession { get }
    var authService: AuthServiceProtocol { get }
}
