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
    @StateObject var authSession = AuthSession.shared
    @AppStorage("appearance_preference") private var appearanceRaw: String = AppearancePreference.system.rawValue
    private let component: AppComponentProtocol

    init() {
        // Crear un componente de dependencias compartido y pasarlo a los containers
        let component = DefaultAppComponent()
        self.component = component

        let initialScreen: AppState.Screen = component.userProfileUseCase
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
                .environmentObject(authSession)
                .preferredColorScheme(AppearancePreference(rawValue: appearanceRaw)?.colorScheme)
                .task {
                    await authSession.bootstrap()
                }
                .onAppear {
                    _ = PhoneConnectivityManager.shared
                    let trainings = component.trainingUseCase.getTrainings()
                    PhoneConnectivityManager.shared.sendTrainings(trainings)
                    KeyboardPreWarm.warm()
                }
        }
    }
}

/// Pre-warm the iOS keyboard subsystem on app launch so the first text-field
/// focus does not pay the lazy initialization cost (~1-3s on first tap).
enum KeyboardPreWarm {
    private static var didWarm = false

    static func warm() {
        guard !didWarm else { return }
        didWarm = true

        // Run after a short delay to let the app finish its first layout.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            guard let window = UIApplication.shared
                .connectedScenes
                .compactMap({ ($0 as? UIWindowScene)?.windows.first(where: { $0.isKeyWindow }) })
                .first else { return }

            let dummy = UITextField(frame: .zero)
            dummy.isHidden = true
            dummy.alpha = 0
            window.addSubview(dummy)

            dummy.becomeFirstResponder()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                dummy.resignFirstResponder()
                dummy.removeFromSuperview()
            }
        }
    }
}
