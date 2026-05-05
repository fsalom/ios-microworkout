import SwiftUI

class WorkoutHistoryRouter {
    private let navigator: NavigatorProtocol
    private let component: AppComponentProtocol

    init(navigator: NavigatorProtocol, component: AppComponentProtocol) {
        self.navigator = navigator
        self.component = component
    }

    func goToLogDetail(_ log: WorkoutLog) {
        navigator.push(to: WorkoutLogDetailBuilder(component: component).build(log: log))
    }

    func goToNewLog(from session: WorkoutSession) {
        navigator.push(to: WorkoutLogEntryBuilder(component: component).build(session: session))
    }

    func goToCurrentSession() {
        navigator.push(to: CurrentSessionBuilder(component: component).build())
    }

    func goToNewSession() {
        let new = WorkoutSession(name: "")
        navigator.push(to: WorkoutSessionEditorBuilder(component: component).build(session: new, isNew: true))
    }

    func goToEditSession(_ session: WorkoutSession) {
        navigator.push(to: WorkoutSessionEditorBuilder(component: component).build(session: session, isNew: false))
    }
}
