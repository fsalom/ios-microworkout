import SwiftUI

@main
struct MicroWorkoutApp: App {

    var body: some Scene {
        WindowGroup {
            RootView(root: TrainingListBuilder().build())
        }
    }
}
