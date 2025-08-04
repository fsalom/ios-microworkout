import SwiftUI

class LoggedExercisesRouter {
    private var navigator: NavigatorProtocol

    init(navigator: NavigatorProtocol) {
        self.navigator = navigator
    }

    func goToWorkoutList() {
        navigator.push(to: TrainingListV2Builder().build())
    }
}
