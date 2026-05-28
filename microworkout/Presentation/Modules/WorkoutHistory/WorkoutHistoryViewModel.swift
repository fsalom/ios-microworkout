import Foundation
import SwiftUI

struct WorkoutHistoryUiState {
    var sessions: [WorkoutSession] = []
    var isLoading: Bool = false
}

final class WorkoutHistoryViewModel: ObservableObject {
    @Published var uiState: WorkoutHistoryUiState = .init()

    private let router: WorkoutHistoryRouter
    private let useCase: WorkoutLogUseCaseProtocol

    init(router: WorkoutHistoryRouter, useCase: WorkoutLogUseCaseProtocol) {
        self.router = router
        self.useCase = useCase
    }

    func load() {
        uiState.isLoading = true
        Task { @MainActor [weak self] in
            guard let self else { return }
            let sessions = (try? await self.useCase.getAllSessions()) ?? []
            self.uiState.sessions = sessions.sorted { $0.updatedAt > $1.updatedAt }
            self.uiState.isLoading = false
        }
    }

    func startNewLog(from session: WorkoutSession) {
        router.goToNewLog(from: session)
    }

    func goToCurrentSession() {
        router.goToCurrentSession()
    }

    func goToNewSession() {
        router.goToNewSession()
    }

    func editSession(_ session: WorkoutSession) {
        router.goToEditSession(session)
    }

    func deleteSession(_ session: WorkoutSession) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            try? await self.useCase.deleteSession(id: session.id.uuidString)
            self.load()
        }
    }
}
