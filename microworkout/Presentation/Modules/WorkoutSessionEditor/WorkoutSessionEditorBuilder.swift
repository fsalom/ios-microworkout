import Foundation

class WorkoutSessionEditorBuilder {
    private let component: AppComponentProtocol

    init(component: AppComponentProtocol) {
        self.component = component
    }

    func build(session: WorkoutSession, isNew: Bool = false) -> WorkoutSessionEditorView {
        let viewModel = WorkoutSessionEditorViewModel(
            session: session,
            isNew: isNew,
            useCase: component.workoutLogUseCase,
            exerciseUseCase: component.exerciseUseCase
        )
        return WorkoutSessionEditorView(viewModel: viewModel)
    }
}
