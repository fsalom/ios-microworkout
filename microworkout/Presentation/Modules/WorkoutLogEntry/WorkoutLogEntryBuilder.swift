import Foundation

class WorkoutLogEntryBuilder {
    private let component: AppComponentProtocol

    init(component: AppComponentProtocol) {
        self.component = component
    }

    /// Build for a NEW log starting from a session template.
    func build(session: WorkoutSession) -> WorkoutLogEntryView {
        let initialLog = WorkoutLog(
            sessionId: session.id,
            sessionName: session.name,
            startedAt: Date(),
            exercises: session.exercises.map { LoggedExercise(exercise: $0) }
        )
        return build(log: initialLog, isNew: true)
    }

    /// Build for editing/continuing an existing log.
    func build(log: WorkoutLog, isNew: Bool = false) -> WorkoutLogEntryView {
        let viewModel = WorkoutLogEntryViewModel(
            log: log,
            isNew: isNew,
            useCase: WorkoutLogContainer(component: component).makeUseCase(),
            exerciseUseCase: ExerciseContainer(component: component).makeUseCase()
        )
        let mediaUseCase = SetMediaContainer(component: component).makeUseCase()
        return WorkoutLogEntryView(viewModel: viewModel, mediaUseCase: mediaUseCase)
    }
}
