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
        Task { @MainActor [weak self] in
            guard let self else { return }
            let sessions = (try? await self.useCase.getAllSessions()) ?? []
            self.uiState.sessions = sessions.sorted { $0.updatedAt > $1.updatedAt }
        }
    }

    func createNew() {
        let new = WorkoutSession(name: "")
        router.goToEditor(new, isNew: true)
    }

    func goToEditor(_ session: WorkoutSession) {
        router.goToEditor(session)
    }

    func delete(_ session: WorkoutSession) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            try? await self.useCase.deleteSession(id: session.id.uuidString)
            self.load()
        }
    }
}
