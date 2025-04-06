import SwiftUI

class TrainingDetailV2Router {
    private var navigator: NavigatorProtocol

    init(navigator: NavigatorProtocol) {
        self.navigator = navigator
    }

    func goToWorkoutList() {
        navigator.push(to: EmptyView())
    }
}
