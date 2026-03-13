import SwiftUI

@main
struct MicroWorkoutApp: App {
    @StateObject var appState: AppState
    @StateObject var mirrorManager = WorkoutMirrorManager.shared
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
                .onAppear {
                    _ = PhoneConnectivityManager.shared
                    let trainings = TrainingContainer(component: component).makeUseCase().getTrainings()
                    PhoneConnectivityManager.shared.sendTrainings(trainings)
                }
        }
    }
}
