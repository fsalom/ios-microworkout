import SwiftUI

@main
struct MicroWorkoutApp: App {
    @StateObject var appState: AppState

    init() {
        let initialScreen: AppState.Screen = UserProfileContainer()
            .makeUseCase()
            .hasCompletedOnboarding() ? .home : .onboarding
        _appState = StateObject(wrappedValue: AppState(initialScreen: initialScreen))
    }

    var body: some Scene {
        WindowGroup {
            RootView(root: SwitcherView())
                .environmentObject(appState)
        }
    }
}
