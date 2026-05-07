import Foundation

class CoachContainer {
    private let component: AppComponentProtocol

    init(component: AppComponentProtocol) {
        self.component = component
    }

    func makeUseCase() -> CoachUseCaseProtocol {
        return CoachUseCase(
            contextUseCase: AIContextContainer(component: component).makeUseCase()
        )
    }
}
