import Foundation

class AIChatBuilder {
    private let component: AppComponentProtocol

    init(component: AppComponentProtocol) {
        self.component = component
    }

    /// - Parameters:
    ///   - topic: área desde la que se abre el chat. Decide el prompt de sistema
    ///     que usa el backend; `.free` para una pregunta suelta del usuario.
    func build(topic: AICoachTopic = .free, initialPrompt: String? = nil) -> AIChatView {
        let viewModel = AIChatViewModel(
            contextUseCase: component.aiContextUseCase,
            chatUseCase: component.aiCoachChatUseCase,
            topic: topic,
            initialPrompt: initialPrompt
        )
        return AIChatView(viewModel: viewModel)
    }
}
