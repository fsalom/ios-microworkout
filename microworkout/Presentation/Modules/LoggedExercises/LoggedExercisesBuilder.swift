import SwiftUI

class LoggedExercisesBuilder {
    private let component: AppComponentProtocol

    init(component: AppComponentProtocol) {
        self.component = component
    }

    func build(for entryDay: WorkoutEntryByDay, linkedWatch: HealthWorkout? = nil) -> LoggedExercisesView {
        let viewModel = LoggedExercisesViewModel(
            router: LoggedExercisesRouter(navigator: Navigator.shared),
            exerciseUseCase: component.exerciseUseCase,
            workoutEntryUseCase: component.workoutEntryUseCase,
            entryDay: entryDay
        )
        return LoggedExercisesView(viewModel: viewModel, linkedWatch: linkedWatch)
    }
}