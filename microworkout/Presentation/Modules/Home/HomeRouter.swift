import SwiftUI

class HomeRouter {
    private var navigator: NavigatorProtocol
    private let component: AppComponentProtocol

    init(navigator: NavigatorProtocol, component: AppComponentProtocol) {
        self.navigator = navigator
        self.component = component
    }

    func goToWorkoutList() {
        navigator.push(to: TrainingListV2Builder(component: component).build())
    }

    func goTo(this entryDay: WorkoutEntryByDay) {
        navigator.push(to: LoggedExercisesBuilder(component: component).build(for: entryDay))
    }

    func goToStart(this training: Training, and appState: AppState) {
        navigator.push(to: TrainingDetailV2Builder(component: component).build(this: training, and: appState))
    }

    func goToHealthWorkoutDetail(_ workout: HealthWorkout) {
        navigator.push(to: HealthWorkoutDetailBuilder(component: component).build(for: workout))
    }
}
