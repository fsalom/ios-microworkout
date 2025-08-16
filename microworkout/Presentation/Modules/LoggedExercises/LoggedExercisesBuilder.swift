import SwiftUI

class LoggedExercisesBuilder {
    func build(for entryDay: WorkoutEntryByDay) -> LoggedExercisesView {
        let viewModel = LoggedExercisesViewModel(
            router: LoggedExercisesRouter(navigator: Navigator.shared),
            exerciseUseCase: ExerciseContainer().makeUseCase(),
            workoutEntryUseCase: WorkoutEntryContainer().makeUseCase(),
            entryDay: entryDay
        )
        return LoggedExercisesView(viewModel: viewModel)
    }
}