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
        uiState.sessions = useCase.getAllSessions().sorted { $0.updatedAt > $1.updatedAt }
        uiState.isLoading = false
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
        useCase.deleteSession(id: session.id.uuidString)
        load()
    }
}
