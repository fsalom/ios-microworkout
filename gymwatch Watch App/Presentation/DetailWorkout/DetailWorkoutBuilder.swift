import Foundation

class DetailWorkoutBuilder {
    @MainActor
    func build(with training: Training) -> DetailWorkoutView {
        let viewModel = DetailWorkoutViewModel(training: training)
        let view = DetailWorkoutView(viewModel: viewModel)
        return view
    }
}
