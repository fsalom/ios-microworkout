import Foundation

class WeeklyPlanBuilder {
    private let component: AppComponentProtocol

    init(component: AppComponentProtocol) {
        self.component = component
    }

    func build() -> WeeklyPlanView {
        let viewModel = WeeklyPlanViewModel(
            useCase: component.weeklyPlanUseCase,
            workoutLogUseCase: component.workoutLogUseCase
        )
        return WeeklyPlanView(viewModel: viewModel)
    }
}
