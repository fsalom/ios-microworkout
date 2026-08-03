import Foundation
import SwiftUI

struct WorkoutSessionListUiState {
    var sessions: [WorkoutSession] = []
    var coachInsight: CoachInsight? = nil
    var isLoadingCoach: Bool = false
}

final class WorkoutSessionListViewModel: ObservableObject {
    @Published var uiState: WorkoutSessionListUiState = .init()

    private let router: WorkoutSessionListRouter
    private let useCase: WorkoutLogUseCaseProtocol
    private let coachUseCase: CoachUseCaseProtocol

    init(
        router: WorkoutSessionListRouter,
        useCase: WorkoutLogUseCaseProtocol,
        coachUseCase: CoachUseCaseProtocol
    ) {
        self.router = router
        self.useCase = useCase
        self.coachUseCase = coachUseCase
    }

    func load() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            let sessions = (try? await self.useCase.getAllSessions()) ?? []
            self.uiState.sessions = sessions.sorted { $0.updatedAt > $1.updatedAt }
        }
        loadCoach()
    }

    private func loadCoach() {
        guard !uiState.isLoadingCoach else { return }
        uiState.isLoadingCoach = true
        Task { @MainActor [weak self] in
            guard let self else { return }
            self.uiState.coachInsight = await self.coachUseCase.planInsight()
            self.uiState.isLoadingCoach = false
        }
    }

    func goToChat(prompt: String) {
        router.goToChat(prompt: prompt, topic: .plan)
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
