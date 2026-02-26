import SwiftUI

@main
struct MicroWorkoutApp: App {
    @StateObject var appState: AppState
    @StateObject var mirrorManager = WorkoutMirrorManager.shared

    init() {
        let initialScreen: AppState.Screen = UserProfileContainer()
            .makeUseCase()
            .hasCompletedOnboarding() ? .home : .onboarding
        _appState = StateObject(wrappedValue: AppState(initialScreen: initialScreen))
        // Register mirroring handler early
        _ = WorkoutMirrorManager.shared
    }

    var body: some Scene {
        WindowGroup {
            RootView(root: SwitcherView())
                .environmentObject(appState)
                .environmentObject(mirrorManager)
                .onAppear {
                    _ = PhoneConnectivityManager.shared
                    let trainings = TrainingContainer().makeUseCase().getTrainings()
                    PhoneConnectivityManager.shared.sendTrainings(trainings)
                }
        }
    }
}
