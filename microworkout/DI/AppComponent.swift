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

    // MARK: Repositorios (cacheados)

    // Un repositorio, UNA instancia. Antes cada use case construía el suyo dentro
    // de su `lazy var` y `syncLocalDataUseCase` volvía a construirlos todos, así
    // que había dos `MealRepository`, dos `TrainingRepository`… sobre los mismos
    // datos. Hoy no se nota porque todo va a UserDefaults, pero en cuanto uno
    // cachee en memoria el banner de sincronización contaría una cosa y la
    // pantalla mostraría otra. `bodyMetricsRepository` tenía el mismo problema
    // disimulado: era un `func`, así que sus dos llamantes recibían instancias
    // distintas pese al comentario que decía que se compartía.

    private lazy var mealRepository: MealRepositoryProtocol = MealRepository(
        localDataSource: MealLocalDataSource(storage: makeUserDefaultsManager()),
        remoteApi: OpenFoodFactsApi(),
        remote: MealRemoteDataSource()
    )

    private lazy var workoutLogRepository: WorkoutLogRepositoryProtocol = WorkoutLogRepository(
        local: WorkoutLogLocalDataSource(localStorage: makeUserDefaultsManager()),
        remote: WorkoutLogRemoteDataSource()
    )

    private lazy var trainingRepository: TrainingRepositoryProtocol = TrainingRepository(
        local: TrainingLocalDataSource(localStorage: makeUserDefaultsManager()),
        remote: TrainingRemoteDataSource()
    )

    private lazy var exerciseRepository: ExerciseRepositoryProtocol = ExerciseRepository(
        local: ExerciseLocalDataSource(localStorage: makeUserDefaultsManager()),
        remote: ExerciseRemoteDataSource()
    )

    private lazy var userProfileRepository: UserProfileRepositoryProtocol = UserProfileRepository(
        local: UserLocalDataSource(storage: makeUserDefaultsManager()),
        remote: UserProfileRemoteDataSource()
    )

    private lazy var weeklyPlanRepository: WeeklyPlanRepositoryProtocol = WeeklyPlanRepository(
        local: WeeklyPlanLocalDataSource(storage: makeUserDefaultsManager()),
        remote: WeeklyPlanRemoteDataSource()
    )

    private lazy var bodyMetricsRepository: BodyMetricsRepositoryProtocol = BodyMetricsRepository(
        health: HealthRepository(
            dataSource: HealthKitDataSource(healthKitManager: makeHealthKitManager())
        ),
        local: BodyMetricsLocalDataSource(storage: makeUserDefaultsManager()),
        remote: BodyMetricsRemoteDataSource()
    )

    // MARK: Use cases (cacheados)

    lazy var mealUseCase: MealUseCaseProtocol = MealUseCase(repository: mealRepository)

    lazy var healthUseCase: HealthUseCaseProtocol = {
        let manager = makeHealthKitManager()
        let dataSource = HealthKitDataSource(healthKitManager: manager)
        let repository = HealthRepository(dataSource: dataSource)
        let linkDataSource = WorkoutLinkLocalDataSource(userDefaults: makeUserDefaultsManager())
        let linkRepository = WorkoutLinkRepository(dataSource: linkDataSource)
        return HealthUseCase(repository: repository, linkRepository: linkRepository)
    }()

    lazy var bodyMetricsUseCase: BodyMetricsUseCaseProtocol =
        BodyMetricsUseCase(repository: bodyMetricsRepository)

    lazy var adaptiveTDEEUseCase: AdaptiveTDEEUseCaseProtocol = AdaptiveTDEEUseCase(
        mealUseCase: mealUseCase,
        bodyMetricsUseCase: bodyMetricsUseCase
    )

    lazy var workoutLogUseCase: WorkoutLogUseCaseProtocol =
        WorkoutLogUseCase(repository: workoutLogRepository)

    lazy var workoutEntryUseCase: WorkoutEntryUseCaseProtocol = {
        let local = WorkoutEntryLocalDataSource(storage: makeUserDefaultsManager())
        let repository = WorkoutEntryRepository(dataSource: local)
        return WorkoutEntryUseCase(repository: repository)
    }()

    lazy var userProfileUseCase: UserProfileUseCaseProtocol =
        UserProfileUseCase(repository: userProfileRepository)

    lazy var trainingUseCase: TrainingUseCaseProtocol =
        TrainingUseCase(repository: trainingRepository)

    lazy var weeklyPlanUseCase: WeeklyPlanUseCaseProtocol = WeeklyPlanUseCase(
        repository: weeklyPlanRepository,
        workoutLogUseCase: workoutLogUseCase
    )

    lazy var exerciseUseCase: ExerciseUseCaseProtocol =
        ExerciseUseCase(repository: exerciseRepository)

    lazy var setMediaUseCase: SetMediaUseCaseProtocol = {
        let local = SetMediaLocalDataSource(storage: makeUserDefaultsManager())
        let repository = SetMediaRepository(localDataSource: local)
        return SetMediaUseCase(repository: repository)
    }()

    lazy var syncLocalDataUseCase: SyncLocalDataUseCaseProtocol = SyncLocalDataUseCase(
        training: trainingRepository,
        workoutLog: workoutLogRepository,
        exercise: exerciseRepository,
        meal: mealRepository,
        userProfile: userProfileRepository,
        bodyMetrics: bodyMetricsRepository,
        weeklyPlan: weeklyPlanRepository
    )

    lazy var exerciseProgressionUseCase: ExerciseProgressionUseCaseProtocol = ExerciseProgressionUseCase(
        logUseCase: workoutLogUseCase,
        mediaUseCase: setMediaUseCase
    )

    lazy var aiContextUseCase: AIContextUseCaseProtocol = AIContextUseCase(
        userProfileUseCase: userProfileUseCase,
        workoutLogUseCase: workoutLogUseCase,
        workoutEntryUseCase: workoutEntryUseCase,
        mealUseCase: mealUseCase,
        healthUseCase: healthUseCase,
        weeklyPlanUseCase: weeklyPlanUseCase,
        adaptiveTDEEUseCase: adaptiveTDEEUseCase
    )

    lazy var aiCoachRepository: AICoachRepositoryProtocol = AICoachRepository(
        remote: AICoachRemoteDataSource()
    )

    lazy var coachFeedbackUseCase: CoachFeedbackUseCaseProtocol = CoachFeedbackUseCase(
        repository: CoachFeedbackRepository(remote: CoachFeedbackRemoteDataSource()),
        storage: makeUserDefaultsManager()
    )

    lazy var coachUseCase: CoachUseCaseProtocol = CoachUseCase(
        contextUseCase: aiContextUseCase,
        repository: aiCoachRepository,
        storage: makeUserDefaultsManager(),
        feedback: coachFeedbackUseCase
    )

    lazy var progressionSuggestionStore: ProgressionSuggestionStoreProtocol =
        ProgressionSuggestionStore(storage: makeUserDefaultsManager())

    lazy var coachActionUseCase: CoachActionUseCaseProtocol = CoachActionUseCase(
        mealUseCase: mealUseCase,
        progressionStore: progressionSuggestionStore,
        feedback: coachFeedbackUseCase
    )

    lazy var aiCoachChatUseCase: AICoachChatUseCaseProtocol = AICoachChatUseCase(
        repository: aiCoachRepository
    )

    lazy var userReportUseCase: UserReportUseCaseProtocol = UserReportUseCase(
        repository: UserReportRepository(remote: UserReportRemoteDataSource())
    )

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
