import Foundation

/// Composition root del app. Cachea cada use case vía `lazy var` para que el
/// grafo de Data/Domain se construya una sola vez por instancia del componente.
///
/// Antes de esta consolidación cada uso pasaba por una clase `XContainer`
/// dedicada. Esas clases se han inlined aquí — toda la creación queda en un
/// único punto y la capa DI se reduce a este archivo + el protocolo.
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

    lazy var mealUseCase: MealUseCase = {
        let localDataSource = MealLocalDataSource(storage: makeUserDefaultsManager())
        let remoteApi = OpenFoodFactsApi()
        let repository = MealRepository(localDataSource: localDataSource, remoteApi: remoteApi)
        return MealUseCase(repository: repository)
    }()

    lazy var healthUseCase: HealthUseCase = {
        let manager = makeHealthKitManager()
        let dataSource = HealthKitDataSource(healthKitManager: manager)
        let repository = HealthRepository(dataSource: dataSource)
        let linkDataSource = WorkoutLinkLocalDataSource(userDefaults: makeUserDefaultsManager())
        let linkRepository = WorkoutLinkRepository(dataSource: linkDataSource)
        return HealthUseCase(repository: repository, linkRepository: linkRepository)
    }()

    lazy var workoutLogUseCase: WorkoutLogUseCaseProtocol = {
        let local = WorkoutLogLocalDataSource(localStorage: makeUserDefaultsManager())
        let repository = WorkoutLogRepository(local: local)
        return WorkoutLogUseCase(repository: repository)
    }()

    lazy var workoutEntryUseCase: WorkoutEntryUseCase = {
        let local = WorkoutEntryLocalDataSource(storage: makeUserDefaultsManager())
        let repository = WorkoutEntryRepository(dataSource: local)
        return WorkoutEntryUseCase(repository: repository)
    }()

    lazy var userProfileUseCase: UserProfileUseCase = {
        let local = UserLocalDataSource(storage: makeUserDefaultsManager())
        let repository = UserProfileRepository(localDataSource: local)
        return UserProfileUseCase(repository: repository)
    }()

    lazy var trainingUseCase: TrainingUseCaseProtocol = {
        let local = TrainingLocalDataSource(localStorage: makeUserDefaultsManager())
        let repository = TrainingRepository(local: local)
        return TrainingUseCase(repository: repository)
    }()

    /// El datasource de Exercise sigue siendo el mock por ahora; la decisión está
    /// pendiente hasta que el backend Python aterrice este recurso.
    lazy var exerciseUseCase: ExerciseUseCase = {
        let mockDataSource: ExerciseDataSourceProtocol = ExerciseMockDataSource()
        let repository: ExerciseRepositoryProtocol = ExerciseRepository(dataSource: mockDataSource)
        return ExerciseUseCase(repository: repository)
    }()

    lazy var setMediaUseCase: SetMediaUseCase = {
        let local = SetMediaLocalDataSource(storage: makeUserDefaultsManager())
        let repository = SetMediaRepository(localDataSource: local)
        return SetMediaUseCase(repository: repository)
    }()

    lazy var exerciseProgressionUseCase: ExerciseProgressionUseCaseProtocol = ExerciseProgressionUseCase(
        logUseCase: workoutLogUseCase,
        mediaUseCase: setMediaUseCase
    )

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
