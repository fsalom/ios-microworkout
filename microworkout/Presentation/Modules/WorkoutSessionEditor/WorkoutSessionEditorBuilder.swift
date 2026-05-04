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
            useCase: WorkoutLogContainer(component: component).makeUseCase(),
            exerciseUseCase: ExerciseContainer(component: component).makeUseCase()
        )
        return WorkoutSessionEditorView(viewModel: viewModel)
    }
}
