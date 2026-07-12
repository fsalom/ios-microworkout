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
        let remote: MealRemoteDataSourceProtocol = MealRemoteDataSource()
        let repository = MealRepository(
            localDataSource: localDataSource,
            remoteApi: remoteApi,
            remote: remote
        )
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
        let remote: WorkoutLogRemoteDataSourceProtocol = WorkoutLogRemoteDataSource()
        let repository = WorkoutLogRepository(local: local, remote: remote)
        return WorkoutLogUseCase(repository: repository)
    }()

    lazy var workoutEntryUseCase: WorkoutEntryUseCase = {
        let local = WorkoutEntryLocalDataSource(storage: makeUserDefaultsManager())
        let repository = WorkoutEntryRepository(dataSource: local)
        return WorkoutEntryUseCase(repository: repository)
    }()

    lazy var userProfileUseCase: UserProfileUseCase = {
        let local = UserLocalDataSource(storage: makeUserDefaultsManager())
        let remote: UserProfileRemoteDataSourceProtocol = UserProfileRemoteDataSource()
        let repository = UserProfileRepository(local: local, remote: remote)
        return UserProfileUseCase(repository: repository)
    }()

    lazy var trainingUseCase: TrainingUseCaseProtocol = {
        let local = TrainingLocalDataSource(localStorage: makeUserDefaultsManager())
        let remote = TrainingRemoteDataSource()
        let repository = TrainingRepository(local: local, remote: remote)
        return TrainingUseCase(repository: repository)
    }()

    lazy var exerciseUseCase: ExerciseUseCase = {
        let local: ExerciseDataSourceProtocol = ExerciseLocalDataSource(localStorage: makeUserDefaultsManager())
        let remote: ExerciseRemoteDataSourceProtocol = ExerciseRemoteDataSource()
        let repository: ExerciseRepositoryProtocol = ExerciseRepository(local: local, remote: remote)
        return ExerciseUseCase(repository: repository)
    }()

    lazy var setMediaUseCase: SetMediaUseCase = {
        let local = SetMediaLocalDataSource(storage: makeUserDefaultsManager())
        let repository = SetMediaRepository(localDataSource: local)
        return SetMediaUseCase(repository: repository)
    }()

    lazy var uploadLocalDataUseCase: UploadLocalDataUseCaseProtocol = {
        let workoutLog = WorkoutLogRepository(
            local: WorkoutLogLocalDataSource(localStorage: makeUserDefaultsManager()),
            remote: WorkoutLogRemoteDataSource())
        let training = TrainingRepository(
            local: TrainingLocalDataSource(localStorage: makeUserDefaultsManager()),
            remote: TrainingRemoteDataSource())
        let exercise = ExerciseRepository(
            local: ExerciseLocalDataSource(localStorage: makeUserDefaultsManager()),
            remote: ExerciseRemoteDataSource())
        let meal = MealRepository(
            localDataSource: MealLocalDataSource(storage: makeUserDefaultsManager()),
            remoteApi: OpenFoodFactsApi(),
            remote: MealRemoteDataSource())
        let userProfile = UserProfileRepository(
            local: UserLocalDataSource(storage: makeUserDefaultsManager()),
            remote: UserProfileRemoteDataSource())
        return UploadLocalDataUseCase(training: training, workoutLog: workoutLog,
                                      exercise: exercise, meal: meal, userProfile: userProfile)
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

    // MARK: Auth

    var authSession: AuthSession { AuthSession.shared }

    lazy var authService: AuthServiceProtocol = AuthService(
        appAuthenticator: Config.shared.appAuthenticator,
        network: Config.shared.network,
        session: AuthSession.shared
    )
}

extension DefaultAppComponent {
    static let preview = DefaultAppComponent()
}
