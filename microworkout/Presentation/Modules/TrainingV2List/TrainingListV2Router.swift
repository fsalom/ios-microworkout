import SwiftUI

class TrainingListV2Router {
    private var navigator: NavigatorProtocol

    init(navigator: NavigatorProtocol) {
        self.navigator = navigator
    }

    func goTo(_ training: Training, and namespace: Namespace.ID) {
        navigator.push(to: TrainingDetailBuilder().build(this: training, and: namespace))
    }
}
