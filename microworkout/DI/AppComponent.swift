import Foundation

/// Implementación por defecto del contenedor de dependencias.
/// Cachea use cases vía `lazy var` para que el grafo se construya una sola vez
/// por instancia de componente, en vez de re-instanciarse desde cada Builder.
final class DefaultAppComponent: AppComponentProtocol {
    init() {}

    // MARK: Proveedores de infraestructura

    func makeUserDefaultsManager() -> UserDefaultsManagerProtocol {
        UserDefaultsManager()
    }

    func makeHealthKitManager() -> HealthKitManagerProtocol {
        HealthKitManager()
    }

    // MARK: Use cases (cacheados)

    lazy var mealUseCase: MealUseCase = MealContainer(component: self).makeUseCase()
    lazy var healthUseCase: HealthUseCase = HealthContainer(component: self).makeUseCase()
    lazy var workoutLogUseCase: WorkoutLogUseCaseProtocol = WorkoutLogContainer(component: self).makeUseCase()
    lazy var workoutEntryUseCase: WorkoutEntryUseCase = WorkoutEntryContainer(component: self).makeUseCase()
    lazy var userProfileUseCase: UserProfileUseCase = UserProfileContainer(component: self).makeUseCase()
    lazy var trainingUseCase: TrainingUseCaseProtocol = TrainingContainer(component: self).makeUseCase()
    lazy var exerciseUseCase: ExerciseUseCase = ExerciseContainer(component: self).makeUseCase()
    lazy var setMediaUseCase: SetMediaUseCase = SetMediaContainer(component: self).makeUseCase()
    lazy var exerciseProgressionUseCase: ExerciseProgressionUseCaseProtocol = ExerciseProgressionContainer(component: self).makeUseCase()

    /// Compone los 5 use cases existentes en vez de re-instanciar el grafo.
    lazy var aiContextUseCase: AIContextUseCaseProtocol = AIContextUseCase(
        userProfileUseCase: userProfileUseCase,
        workoutLogUseCase: workoutLogUseCase,
        workoutEntryUseCase: workoutEntryUseCase,
        mealUseCase: mealUseCase,
        healthUseCase: healthUseCase
    )

    lazy var coachUseCase: CoachUseCaseProtocol = CoachUseCase(contextUseCase: aiContextUseCase)
}

extension DefaultAppComponent {
    static let preview = DefaultAppComponent()
}
