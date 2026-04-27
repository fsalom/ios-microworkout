import SwiftUI

class HealthWorkoutDetailRouter {
    private var navigator: NavigatorProtocol
    private let component: AppComponentProtocol

    init(navigator: NavigatorProtocol, component: AppComponentProtocol) {
        self.navigator = navigator
        self.component = component
    }

    func goTo(entry: WorkoutEntryByDay) {
        navigator.push(to: LoggedExercisesBuilder(component: component).build(for: entry))
    }
}
