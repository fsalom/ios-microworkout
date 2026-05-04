import Foundation
import SwiftUI

struct WorkoutSessionListUiState {
    var sessions: [WorkoutSession] = []
}

final class WorkoutSessionListViewModel: ObservableObject {
    @Published var uiState: WorkoutSessionListUiState = .init()

    private let router: WorkoutSessionListRouter
    private let useCase: WorkoutLogUseCaseProtocol

    init(router: WorkoutSessionListRouter, useCase: WorkoutLogUseCaseProtocol) {
        self.router = router
        self.useCase = useCase
    }

    func load() {
        uiState.sessions = useCase.getAllSessions().sorted { $0.updatedAt > $1.updatedAt }
    }

    func createNew() {
        let new = WorkoutSession(name: "")
        router.goToEditor(new, isNew: true)
    }

    func goToEditor(_ session: WorkoutSession) {
        router.goToEditor(session)
    }

    func delete(_ session: WorkoutSession) {
        useCase.deleteSession(id: session.id.uuidString)
        load()
    }
}
