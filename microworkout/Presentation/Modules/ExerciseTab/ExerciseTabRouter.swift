import SwiftUI

class ExerciseTabRouter {
    private let navigator: NavigatorProtocol
    private let component: AppComponentProtocol

    init(navigator: NavigatorProtocol, component: AppComponentProtocol) {
        self.navigator = navigator
        self.component = component
    }

    func goTo(this entryDay: WorkoutEntryByDay) {
        navigator.push(to: LoggedExercisesBuilder(component: component).build(for: entryDay))
    }

    func goToLinked(entry: WorkoutEntryByDay, watch: HealthWorkout) {
        navigator.push(to: LoggedExercisesBuilder(component: component).build(for: entry, linkedWatch: watch))
    }

    func goToHealthWorkoutDetail(_ workout: HealthWorkout) {
        navigator.push(to: HealthWorkoutDetailBuilder(component: component).build(for: workout))
    }

    func goToLogDetail(_ log: WorkoutLog) {
        navigator.push(to: WorkoutLogDetailBuilder(component: component).build(log: log))
    }

    func goToChat(prompt: String) {
        navigator.push(to: AIChatBuilder(component: component).build(initialPrompt: prompt))
    }
}
