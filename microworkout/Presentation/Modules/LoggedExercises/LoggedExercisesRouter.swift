import SwiftUI

class LoggedExercisesRouter {
    private var navigator: NavigatorProtocol

    init(navigator: NavigatorProtocol) {
        self.navigator = navigator
    }

    func comeBack() {
        navigator.dismiss()
    }
}
