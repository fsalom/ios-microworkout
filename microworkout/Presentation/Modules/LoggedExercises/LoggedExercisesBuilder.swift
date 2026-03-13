import SwiftUI

class LoggedExercisesBuilder {
    private let component: AppComponentProtocol

    init(component: AppComponentProtocol) {
        self.component = component
    }

    func build(for entryDay: WorkoutEntryByDay) -> LoggedExercisesView {
        let viewModel = LoggedExercisesViewModel(
            router: LoggedExercisesRouter(navigator: Navigator.shared),
            exerciseUseCase: ExerciseContainer(component: component).makeUseCase(),
            workoutEntryUseCase: WorkoutEntryContainer(component: component).makeUseCase(),
            entryDay: entryDay
        )
        return LoggedExercisesView(viewModel: viewModel)
    }
}