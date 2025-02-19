import SwiftUI

class TrainingListRouter {
    private var navigator: NavigatorProtocol

    init(navigator: NavigatorProtocol) {
        self.navigator = navigator
    }

    func goTo(_ training: Training) {
        navigator.push(to: TrainingDetailBuilder().build(this: training))
    }
}
