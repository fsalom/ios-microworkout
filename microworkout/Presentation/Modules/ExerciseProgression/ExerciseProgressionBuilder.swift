import Foundation
import SwiftUI

class ExerciseProgressionBuilder {
    private let component: AppComponentProtocol

    init(component: AppComponentProtocol) {
        self.component = component
    }

    func build(sourceSetId: UUID, navigator: NavigatorProtocol = Navigator.shared) -> ExerciseProgressionView {
        let progressionUseCase = ExerciseProgressionContainer(component: component).makeUseCase()
        let mediaUseCase = SetMediaContainer(component: component).makeUseCase()
        let router = ExerciseProgressionRouter(navigator: navigator)
        let viewModel = ExerciseProgressionViewModel(
            sourceSetId: sourceSetId,
            progressionUseCase: progressionUseCase,
            mediaUseCase: mediaUseCase,
            router: router
        )
        return ExerciseProgressionView(viewModel: viewModel)
    }
}
