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
    var hasCycling: Bool = false
    var strictDayCalorieTarget: Double = 0
    var freeDayCalorieTarget: Double = 0
    var healthKitStatus: HealthAuthorizationStatus = .notDetermined
    var isHealthDataAvailable: Bool = false
}

class ProfileViewModel: ObservableObject {
    @Published var uiState: ProfileUiState = .init()

    private var userProfileUseCase: UserProfileUseCaseProtocol
    private var healthUseCase: HealthUseCaseProtocol
    private let authService: AuthServiceProtocol
    private let syncLocalDataUseCase: SyncLocalDataUseCaseProtocol

    init(userProfileUseCase: UserProfileUseCaseProtocol,
         healthUseCase: HealthUseCaseProtocol,
         authService: AuthServiceProtocol,
         syncLocalDataUseCase: SyncLocalDataUseCaseProtocol) {
        self.userProfileUseCase = userProfileUseCase
        self.healthUseCase = healthUseCase
        self.authService = authService
        self.syncLocalDataUseCase = syncLocalDataUseCase
        loadProfile()
        loadHealthKitStatus()
    }

    /// Comprueba (sin escribir nada) qué datos locales faltan por subir a la
    /// cuenta, categoría a categoría. Requiere estar autenticado.
    func loadSyncStatus() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            guard AuthSession.shared.state.isAuthenticated else { return }
            guard !self.uiState.isSyncing, !self.uiState.isLoadingSyncStatus else { return }
            self.uiState.isLoadingSyncStatus = true
            let report = await self.syncLocalDataUseCase.status()
            self.uiState.syncReport = report
            self.uiState.hasLoadedSyncStatus = true
            self.uiState.isLoadingSyncStatus = false
            // Si el token murió, SessionAwareNetwork (infra) ya pasó a invitado; avisamos.
            if !AuthSession.shared.state.isAuthenticated {
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
            guard AuthSession.shared.state.isAuthenticated else { return }
            guard !self.uiState.isSyncing else { return }
            self.uiState.isSyncing = true
            self.uiState.lastSyncMessage = nil
            let report = await self.syncLocalDataUseCase.sync()
            self.uiState.syncReport = report
            self.uiState.hasLoadedSyncStatus = true
            // SessionAwareNetwork ya habrá pasado a invitado si el token murió.
            let expired = !AuthSession.shared.state.isAuthenticated
            self.uiState.lastSyncMessage = expired ? Self.sessionExpiredMessage : Self.syncSummary(for: report)
            self.uiState.isSyncing = false
        }
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
                self.uiState.hasCycling = profile.hasCycling
                self.uiState.strictDayCalorieTarget = profile.strictDayCalorieTarget
                self.uiState.freeDayCalorieTarget = profile.freeDayCalorieTarget
            } catch {
                // Si el token murió, SessionAwareNetwork (infra) ya pasó a invitado;
                // aquí solo mostramos el aviso. Otros errores (red transitoria):
                // mantenemos el último estado conocido.
                if !AuthSession.shared.state.isAuthenticated {
                    self.uiState.authError = Self.sessionExpiredMessage
                }
            }
        }
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
            freeDayExtraCalories: uiState.freeDays.isEmpty ? nil : uiState.freeDayExtraCalories
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
