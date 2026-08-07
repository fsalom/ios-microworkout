import Foundation

class WeightProgressBuilder {
    private let component: AppComponentProtocol

    init(component: AppComponentProtocol) {
        self.component = component
    }

    func build() -> WeightProgressView {
        let viewModel = WeightProgressViewModel(useCase: component.bodyMetricsUseCase)
        return WeightProgressView(viewModel: viewModel)
    }
}
