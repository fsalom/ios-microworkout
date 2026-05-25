import SwiftUI

class ExerciseProgressionRouter {
    private var navigator: NavigatorProtocol

    init(navigator: NavigatorProtocol) {
        self.navigator = navigator
    }

    func goBack() {
        navigator.dismiss()
    }
}
