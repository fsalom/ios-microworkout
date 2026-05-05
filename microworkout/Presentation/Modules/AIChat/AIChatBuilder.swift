import Foundation

class AIChatBuilder {
    private let component: AppComponentProtocol

    init(component: AppComponentProtocol) {
        self.component = component
    }

    func build(initialPrompt: String? = nil) -> AIChatView {
        let viewModel = AIChatViewModel(
            useCase: AIContextContainer(component: component).makeUseCase(),
            initialPrompt: initialPrompt
        )
        return AIChatView(viewModel: viewModel)
    }
}
