import SwiftUI

class HomeRouter {
    private var navigator: NavigatorProtocol

    init(navigator: NavigatorProtocol) {
        self.navigator = navigator
    }

    func goToWorkoutList() {
        navigator.push(to: TrainingListV2Builder().build())
    }

    func goToStart(this training: Training, and namespace: Namespace.ID) {
        navigator.push(to: TrainingDetailV2Builder().build(this: training, and: namespace))
    }
}
