import Foundation
import SwiftUI

class ExerciseProgressionBuilder {
    private let component: AppComponentProtocol

    init(component: AppComponentProtocol) {
        self.component = component
    }

    func build(sourceSetId: UUID) -> ExerciseProgressionView {
        let progressionUseCase = ExerciseProgressionContainer(component: component).makeUseCase()
        let mediaUseCase = SetMediaContainer(component: component).makeUseCase()
        let viewModel = ExerciseProgressionViewModel(
            sourceSetId: sourceSetId,
            progressionUseCase: progressionUseCase,
            mediaUseCase: mediaUseCase
        )
        return ExerciseProgressionView(viewModel: viewModel)
    }
}
