import SwiftUI

@main
struct MicroWorkoutApp: App {
    @StateObject var appState: AppState = AppState()

    var body: some Scene {
        WindowGroup {
            RootView(root: SwitcherView())
                .environmentObject(appState)
        }
    }
}
