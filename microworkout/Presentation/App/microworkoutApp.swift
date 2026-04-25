import SwiftUI

enum AppearancePreference: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var label: String {
        switch self {
        case .system: return "Automático"
        case .light:  return "Claro"
        case .dark:   return "Oscuro"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }
}

@main
struct MicroWorkoutApp: App {
    @StateObject var appState: AppState
    @StateObject var mirrorManager = WorkoutMirrorManager.shared
    @AppStorage("appearance_preference") private var appearanceRaw: String = AppearancePreference.system.rawValue
    private let component: AppComponentProtocol

    init() {
        // Crear un componente de dependencias compartido y pasarlo a los containers
        let component = DefaultAppComponent()
        self.component = component

        let initialScreen: AppState.Screen = UserProfileContainer(component: component)
            .makeUseCase()
            .hasCompletedOnboarding() ? .home : .onboarding
        _appState = StateObject(wrappedValue: AppState(initialScreen: initialScreen))
        // Register mirroring handler early
        _ = WorkoutMirrorManager.shared
    }

    var body: some Scene {
        WindowGroup {
            RootView(root: SwitcherView(component: component), component: component)
                .environmentObject(appState)
                .environmentObject(mirrorManager)
                .preferredColorScheme(AppearancePreference(rawValue: appearanceRaw)?.colorScheme)
                .onAppear {
                    _ = PhoneConnectivityManager.shared
                    let trainings = TrainingContainer(component: component).makeUseCase().getTrainings()
                    PhoneConnectivityManager.shared.sendTrainings(trainings)
                }
        }
    }
}
