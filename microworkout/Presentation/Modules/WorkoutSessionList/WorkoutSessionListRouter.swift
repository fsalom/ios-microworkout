import SwiftUI

class WorkoutSessionListRouter {
    private let navigator: NavigatorProtocol
    private let component: AppComponentProtocol

    init(navigator: NavigatorProtocol, component: AppComponentProtocol) {
        self.navigator = navigator
        self.component = component
    }

    func goToEditor(_ session: WorkoutSession, isNew: Bool = false) {
        navigator.push(to: WorkoutSessionEditorBuilder(component: component).build(session: session, isNew: isNew))
    }

    func goToChat(prompt: String, topic: AICoachTopic) {
        navigator.push(
            to: AIChatBuilder(component: component).build(topic: topic, initialPrompt: prompt)
        )
    }
}
