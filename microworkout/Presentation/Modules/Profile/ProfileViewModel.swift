import SwiftUI
import Combine
import UIKit
import AuthenticationServices

struct ProfileUiState {
    var authError: String?
    var authSuccessMessage: String?
    var isSigningIn: Bool = false
    var isSyncing: Bool = false
    var isLoadingSyncStatus: Bool = false
    var hasLoadedSyncStatus: Bool = false
    var syncReport: SyncReport = .empty()
    var lastSyncMessage: String?
    var name: String = ""
    var weight: Double = 70
    var height: Double = 170
    var age: Int = 30
    var gender: UserProfile.Gender = .male
    var activityLevel: UserProfile.ActivityLevel = .moderate
    var fitnessGoal: UserProfile.FitnessGoal = .maintain
    var macroProfile: UserProfile.MacroProfile = .balanced
    var hasProfile: Bool = false
    var dailyCalorieTarget: Double = 0
    var macroTargets: NutritionInfo = .zero
    var isEditing: Bool = false
    var freeDays: Set<Int> = []
    var freeDayExtraCalories: Double = 500
    /// Objetivo diario en el formulario, en texto. Arranca con el CALCULADO, así que
    /// el campo nunca sale vacío y ajustarlo es tocar un número, no inventarlo.
    var calorieTargetInput: String = ""
    /// El de la fórmula, para poder mostrarlo y volver a él.
    var calculatedCalorieTarget: Double = 0

    /// `true` si lo escrito difiere del calculado, o sea si el usuario ha puesto lo suyo.
    var isUsingCustomCalorieTarget: Bool {
        ProfileViewModel.calorieOverride(
            from: calorieTargetInput, calculated: calculatedCalorieTarget
        ) != nil
    }
    var hasCycling: Bool = false
    var strictDayCalorieTarget: Double = 0
    var freeDayCalorieTarget: Double = 0
    /// Cómo quiere que le hable el coach. Por defecto, como siempre.
    var coachTone: UserProfile.CoachTone = .close
    var coachDetail: UserProfile.CoachDetail = .normal
    var coachAvoidWeightTalk: Bool = false
    /// Mensaje cuando un cambio de preferencia no se pudo guardar.
    var coachPreferencesError: String?
    var healthKitStatus: HealthAuthorizationStatus = .notDetermined
    var isHealthDataAvailable: Bool = false
    /// Avisos proactivos del coach (brief de la mañana, cierre de la noche).
    var coachBriefsEnabled: Bool = false
    /// Mensaje cuando el sistema denegó el permiso de notificaciones.
    var coachBriefsError: String?
    /// Gasto real estimado a partir de comidas y peso. `nil` = aún sin datos.
    var tdeeEstimate: TDEEEstimate?

    /// Objetivo coherente con el gasto real medido y el objetivo físico elegido.
    var tdeeSuggestedTarget: Double? {
        tdeeEstimate.map { $0.suggestedTarget(for: fitnessGoal).rounded() }
    }

    /// `true` si merece la pena ofrecer el ajuste: la sugerencia existe y se
    /// separa de lo que hay puesto. Por debajo de 50 kcal es ruido de medición,
    /// no una desviación que corregir.
    var tdeeSuggestionDiffers: Bool {
        guard let suggested = tdeeSuggestedTarget else { return false }
        let current = ProfileViewModel.calorieOverride(
            from: calorieTargetInput, calculated: calculatedCalorieTarget
        ) ?? calculatedCalorieTarget
        return abs(suggested - current) >= 50
    }
}

class ProfileViewModel: ObservableObject {
    @Published var uiState: ProfileUiState = .init()

    private let router: ProfileRouterProtocol
    /// Opcional: los tests del formulario no lo necesitan y el resto de la
    /// pantalla funciona igual sin él (la sección simplemente no aparece).
    private let adaptiveTDEEUseCase: AdaptiveTDEEUseCaseProtocol?
    /// Ídem: sin él, el interruptor de avisos no se pinta.
    private let coachBriefsUseCase: CoachBriefsUseCaseProtocol?
    private var userProfileUseCase: UserProfileUseCaseProtocol
    private var healthUseCase: HealthUseCaseProtocol
    private let authService: AuthServiceProtocol
    private let syncLocalDataUseCase: SyncLocalDataUseCaseProtocol
    /// Quién decide si hay sesión. Inyectado y no `AuthSession.shared`: el
    /// singleton es estado global y hacía este ViewModel imposible de testear —
    /// justo el motivo por el que los repositorios ya reciben su sesión.
    private let session: AuthStateProviding

    init(router: ProfileRouterProtocol,
         adaptiveTDEEUseCase: AdaptiveTDEEUseCaseProtocol? = nil,
         coachBriefsUseCase: CoachBriefsUseCaseProtocol? = nil,
         userProfileUseCase: UserProfileUseCaseProtocol,
         healthUseCase: HealthUseCaseProtocol,
         authService: AuthServiceProtocol,
         syncLocalDataUseCase: SyncLocalDataUseCaseProtocol,
         session: AuthStateProviding = SharedAuthState()) {
        self.router = router
        self.adaptiveTDEEUseCase = adaptiveTDEEUseCase
        self.coachBriefsUseCase = coachBriefsUseCase
        self.userProfileUseCase = userProfileUseCase
        self.healthUseCase = healthUseCase
        self.authService = authService
        self.syncLocalDataUseCase = syncLocalDataUseCase
        self.session = session
        loadProfile()
        loadHealthKitStatus()
    }

    // MARK: - Navegación

    func goToChat() { router.goToChat() }
    func goToWeightProgress() { router.goToWeightProgress() }
    func goToUserReport() { router.goToUserReport() }

    /// Comprueba (sin escribir nada) qué datos locales faltan por subir a la
    /// cuenta, categoría a categoría. Requiere estar autenticado.
    func loadSyncStatus() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            guard await self.session.isAuthenticated else { return }
            guard !self.uiState.isSyncing, !self.uiState.isLoadingSyncStatus else { return }
            self.uiState.isLoadingSyncStatus = true
            let report = await self.syncLocalDataUseCase.status()
            self.uiState.syncReport = report
            self.uiState.hasLoadedSyncStatus = true
            self.uiState.isLoadingSyncStatus = false
            // Si el token murió, SessionAwareNetwork (infra) ya pasó a invitado; avisamos.
            if await !self.session.isAuthenticated {
                self.uiState.lastSyncMessage = Self.sessionExpiredMessage
            }
        }
    }

    /// Sincroniza con la cuenta: sube lo que falte en cada categoría (la copia
    /// local se conserva siempre como respaldo) y refleja el resultado por
    /// categoría en `syncReport`. Requiere estar autenticado.
    func sync() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            guard await self.session.isAuthenticated else { return }
            guard !self.uiState.isSyncing else { return }
            self.uiState.isSyncing = true
            self.uiState.lastSyncMessage = nil
            let report = await self.syncLocalDataUseCase.sync()
            self.uiState.syncReport = report
            self.uiState.hasLoadedSyncStatus = true
            // SessionAwareNetwork ya habrá pasado a invitado si el token murió.
            let expired = await !self.session.isAuthenticated
            self.uiState.lastSyncMessage = expired ? Self.sessionExpiredMessage : Self.syncSummary(for: report)
            self.uiState.isSyncing = false
        }
    }

    /// El objetivo escrito, o `nil` si es el calculado (o no es un número usable).
    static func calorieOverride(from input: String, calculated: Double) -> Double? {
        let normalized = input
            .replacingOccurrences(of: ".", with: "")
            .replacingOccurrences(of: ",", with: ".")
            .trimmingCharacters(in: .whitespaces)
        guard let value = Double(normalized), value > 0 else { return nil }
        // Un redondeo de menos de 1 kcal no es una elección del usuario.
        guard abs(value - calculated.rounded()) >= 1 else { return nil }
        return value
    }

    static let sessionExpiredMessage = "Tu sesión ha caducado. Vuelve a iniciar sesión."

    /// Resumen legible del resultado de una sincronización.
    private static func syncSummary(for report: SyncReport) -> String {
        if report.hasErrors {
            if report.totalUploaded > 0 {
                return "Se subieron \(report.totalUploaded), pero algunas categorías fallaron. Reinténtalo."
            }
            return "No se pudo sincronizar. Revisa tu conexión y reinténtalo."
        }
        if report.totalUploaded > 0 {
            return "Sincronizados \(report.totalUploaded) elementos con tu cuenta."
        }
        return "Todo está al día en tu cuenta."
    }

    func loadProfile() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                guard let profile = try await self.userProfileUseCase.getProfile() else {
                    // No hay perfil (invitado sin perfil local, o cuenta nueva):
                    // el hub muestra el CTA "Completa tu perfil", no datos antiguos.
                    self.uiState.hasProfile = false
                    return
                }
                self.uiState.name = profile.name
                self.uiState.weight = profile.weight
                self.uiState.height = profile.height
                self.uiState.age = profile.age
                self.uiState.gender = profile.gender
                self.uiState.activityLevel = profile.activityLevel
                self.uiState.fitnessGoal = profile.resolvedGoal
                self.uiState.macroProfile = profile.resolvedMacroProfile
                self.uiState.hasProfile = true
                self.uiState.dailyCalorieTarget = profile.dailyCalorieTarget
                self.uiState.macroTargets = profile.macroTargets
                self.uiState.freeDays = profile.resolvedFreeDays
                self.uiState.freeDayExtraCalories = profile.resolvedFreeDayExtra
                self.uiState.calculatedCalorieTarget = profile.calculatedCalorieTarget
                // Precargado con el objetivo en vigor: el suyo si lo puso, el
                // calculado si no.
                self.uiState.calorieTargetInput = String(Int(profile.dailyCalorieTarget.rounded()))
                self.uiState.hasCycling = profile.hasCycling
                self.uiState.strictDayCalorieTarget = profile.strictDayCalorieTarget
                self.uiState.freeDayCalorieTarget = profile.freeDayCalorieTarget
                // Punto de retorno si un cambio de preferencia falla al guardarse.
                self.persistedCoachPreferences = CoachPreferences(
                    tone: profile.coachTone ?? .close,
                    detail: profile.coachDetail ?? .normal,
                    avoidWeightTalk: profile.coachAvoidWeightTalk ?? false
                )
                self.apply(self.persistedCoachPreferences)
            } catch {
                // Si el token murió, SessionAwareNetwork (infra) ya pasó a invitado;
                // aquí solo mostramos el aviso. Otros errores (red transitoria):
                // mantenemos el último estado conocido.
                if await !self.session.isAuthenticated {
                    self.uiState.authError = Self.sessionExpiredMessage
                }
            }
        }
    }

    /// El interruptor de los avisos. Si el sistema deniega el permiso, el toggle
    /// vuelve a apagado y se explica dónde encenderlo — dejarlo en verde sin
    /// permiso sería mentir.
    func setCoachBriefs(enabled: Bool) {
        guard let coachBriefsUseCase else { return }
        Task { @MainActor [weak self] in
            guard let self else { return }
            if enabled {
                let granted = await coachBriefsUseCase.enable()
                self.uiState.coachBriefsEnabled = granted
                self.uiState.coachBriefsError = granted
                    ? nil
                    : "Las notificaciones están desactivadas. Actívalas en Ajustes > microworkout."
            } else {
                await coachBriefsUseCase.disable()
                self.uiState.coachBriefsEnabled = false
                self.uiState.coachBriefsError = nil
            }
        }
    }

    func loadCoachBriefsState() {
        uiState.coachBriefsEnabled = coachBriefsUseCase?.isEnabled ?? false
    }

    /// Calcula el gasto real en segundo plano. Se llama al cargar el perfil; si
    /// no hay datos suficientes, el estado se queda en `nil` y no se pinta nada.
    func loadRealExpenditure() {
        guard let adaptiveTDEEUseCase else { return }
        Task { @MainActor [weak self] in
            guard let self else { return }
            self.uiState.tdeeEstimate = await adaptiveTDEEUseCase.estimate()
        }
    }

    /// Adopta como objetivo el que sale del gasto medido. Pasa por `save()` para
    /// que siga la misma regla de siempre: si coincide con el calculado no se
    /// guarda como override, y los macros y días libres se recalculan sobre él.
    func applyTDEESuggestedTarget() {
        guard let suggested = uiState.tdeeSuggestedTarget else { return }
        uiState.calorieTargetInput = String(Int(suggested))
        save()
    }

    /// Devuelve el campo al valor de la fórmula.
    func resetCalorieTargetToCalculated() {
        uiState.calorieTargetInput = String(Int(uiState.calculatedCalorieTarget.rounded()))
    }

    func startEditing() {
        uiState.isEditing = true
    }

    func cancelEditing() {
        loadProfile()
        uiState.isEditing = false
    }

    func save() {
        let profile = UserProfile(
            name: uiState.name.isEmpty ? "Usuario" : uiState.name,
            height: uiState.height,
            weight: uiState.weight,
            age: uiState.age,
            gender: uiState.gender,
            activityLevel: uiState.activityLevel,
            fitnessGoal: uiState.fitnessGoal,
            macroProfile: uiState.macroProfile,
            freeDays: uiState.freeDays.isEmpty ? nil : Array(uiState.freeDays),
            freeDayExtraCalories: uiState.freeDays.isEmpty ? nil : uiState.freeDayExtraCalories,
            // Solo se guarda como override si DIFIERE del calculado: si el usuario no
            // lo toca, el objetivo debe seguir moviéndose con su peso y su actividad
            // en vez de quedarse congelado el día que abrió el formulario.
            calorieTargetOverride: Self.calorieOverride(
                from: uiState.calorieTargetInput,
                calculated: uiState.calculatedCalorieTarget
            ),
            coachTone: uiState.coachTone,
            coachDetail: uiState.coachDetail,
            coachAvoidWeightTalk: uiState.coachAvoidWeightTalk
        )
        userProfileUseCase.setOnboardingCompleted(true)
        uiState.hasProfile = true
        uiState.dailyCalorieTarget = profile.dailyCalorieTarget
        uiState.macroTargets = profile.macroTargets
        uiState.hasCycling = profile.hasCycling
        uiState.strictDayCalorieTarget = profile.strictDayCalorieTarget
        uiState.freeDayCalorieTarget = profile.freeDayCalorieTarget
        uiState.isEditing = false
        Task { try? await userProfileUseCase.saveProfile(profile) }
    }

    /// Guarda solo las preferencias del coach.
    ///
    /// Aparte de `save()` porque no viven dentro del modo edición del perfil: se
    /// cambian con un toque y deben quedar guardadas al momento, sin obligar a
    /// entrar a editar y darle a Guardar.
    ///
    /// Si el guardado falla se REVIERTE el control y se avisa. Antes iba con `try?`
    /// y sin feedback: el interruptor se quedaba puesto, la pantalla decía que el
    /// coach ya te hablaba así, y no se había guardado nada. Un ajuste que se aplica
    /// con un toque necesita decir cuándo NO se aplicó.
    func saveCoachPreferences() {
        // Se captura lo que el usuario acaba de elegir: entre el toque y la
        // respuesta del servidor puede haber tocado otra cosa, y lo que hay que
        // guardar es esto, no lo que haya en `uiState` cuando vuelva.
        let desired = CoachPreferences(
            tone: uiState.coachTone,
            detail: uiState.coachDetail,
            avoidWeightTalk: uiState.coachAvoidWeightTalk
        )

        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                guard var profile = try await self.userProfileUseCase.getProfile() else {
                    // Sin perfil no hay dónde colgar las preferencias. Para el
                    // usuario el efecto es el mismo que un fallo: no se guardó.
                    throw DomainError.notFound
                }
                profile.coachTone = desired.tone
                profile.coachDetail = desired.detail
                profile.coachAvoidWeightTalk = desired.avoidWeightTalk
                try await self.userProfileUseCase.saveProfile(profile)
                self.persistedCoachPreferences = desired
                self.uiState.coachPreferencesError = nil
            } catch {
                self.apply(self.persistedCoachPreferences)
                self.uiState.coachPreferencesError = "No se pudo guardar. Inténtalo de nuevo."
            }
        }
    }

    /// Las tres preferencias juntas: se guardan y se revierten como una unidad.
    struct CoachPreferences: Equatable {
        var tone: UserProfile.CoachTone = .close
        var detail: UserProfile.CoachDetail = .normal
        var avoidWeightTalk: Bool = false
    }

    /// Lo último que se sabe guardado, para poder volver ahí si falla.
    private var persistedCoachPreferences = CoachPreferences()

    @MainActor
    private func apply(_ preferences: CoachPreferences) {
        uiState.coachTone = preferences.tone
        uiState.coachDetail = preferences.detail
        uiState.coachAvoidWeightTalk = preferences.avoidWeightTalk
    }

    // MARK: - HealthKit

    func loadHealthKitStatus() {
        uiState.isHealthDataAvailable = healthUseCase.isHealthDataAvailable
        uiState.healthKitStatus = healthUseCase.authorizationStatus
    }

    func requestHealthKit() {
        Task { @MainActor in
            _ = try? await healthUseCase.requestAuthorization()
            loadHealthKitStatus()
        }
    }

    func openHealthApp() {
        guard let url = URL(string: "x-apple-health://") else { return }
        UIApplication.shared.open(url)
    }

    // MARK: - Authentication

    func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .failure(let error):
            if (error as? ASAuthorizationError)?.code == .canceled { return }
            uiState.authError = error.localizedDescription
        case .success(let auth):
            guard
                let credential = auth.credential as? ASAuthorizationAppleIDCredential,
                let codeData = credential.authorizationCode,
                let code = String(data: codeData, encoding: .utf8)
            else {
                uiState.authError = "No se obtuvo código de autorización de Apple"
                return
            }
            Task { @MainActor in
                uiState.isSigningIn = true
                defer { uiState.isSigningIn = false }
                do {
                    try await authService.signInWithApple(authCode: code)
                    uiState.authSuccessMessage = "Sesión iniciada"
                    sync()   // auto-sincroniza lo local al iniciar sesión
                } catch {
                    uiState.authError = Self.authErrorText(error)
                }
            }
        }
    }

    /// Inicia sesión con Google. El SDK y la presentación viven en `AuthService`
    /// (infra); aquí solo orquestamos el estado de UI y la auto-sincronización.
    @MainActor
    func handleGoogleSignIn() {
        Task { @MainActor in
            uiState.isSigningIn = true
            defer { uiState.isSigningIn = false }
            do {
                try await authService.signInWithGoogle()
                uiState.authSuccessMessage = "Sesión iniciada con Google"
                sync()   // auto-sincroniza lo local al iniciar sesión
            } catch AuthServiceError.cancelled {
                return
            } catch {
                uiState.authError = Self.authErrorText(error)
            }
        }
    }

    /// Traduce un error de inicio de sesión a un mensaje claro para el usuario.
    static func authErrorText(_ error: Error) -> String {
        let ns = error as NSError
        if ns.domain == NSURLErrorDomain {
            return "No se pudo conectar. Revisa tu conexión e inténtalo de nuevo."
        }
        return "No se pudo iniciar sesión. Inténtalo de nuevo."
    }

    func signOut() {
        Task { @MainActor in
            await authService.logout()
        }
    }

    func dismissAuthError() {
        uiState.authError = nil
    }

    func dismissAuthSuccess() {
        uiState.authSuccessMessage = nil
    }
}
