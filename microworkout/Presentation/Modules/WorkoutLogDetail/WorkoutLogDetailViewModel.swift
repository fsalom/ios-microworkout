import Foundation
import SwiftUI

struct WorkoutLogDetailUiState {
    var log: WorkoutLog
    var expandedNotes: Set<UUID> = []
    var linkedHealthWorkout: HealthWorkout? = nil
}

final class WorkoutLogDetailViewModel: ObservableObject {
    @Published var uiState: WorkoutLogDetailUiState

    private let useCase: WorkoutLogUseCaseProtocol
    private let healthUseCase: HealthUseCaseProtocol

    init(log: WorkoutLog,
         useCase: WorkoutLogUseCaseProtocol,
         healthUseCase: HealthUseCaseProtocol) {
        self.uiState = .init(log: log)
        self.useCase = useCase
        self.healthUseCase = healthUseCase
        self.uiState.expandedNotes = Set(log.exercises.filter { ($0.notes?.isEmpty == false) }.map { $0.id })
        loadLinkedHealthWorkout()
    }

    func delete() -> Bool {
        useCase.deleteLog(id: uiState.log.id.uuidString)
        return true
    }

    func toggleNotes(for exerciseLogId: UUID) {
        if uiState.expandedNotes.contains(exerciseLogId) {
            uiState.expandedNotes.remove(exerciseLogId)
        } else {
            uiState.expandedNotes.insert(exerciseLogId)
        }
    }

    private func loadLinkedHealthWorkout() {
        guard let linkedId = uiState.log.linkedHealthWorkoutId?.uuidString else { return }
        Task { @MainActor in
            let workouts = (try? await healthUseCase.getRecentWorkouts()) ?? []
            self.uiState.linkedHealthWorkout = workouts.first { $0.id == linkedId }
        }
    }
}
