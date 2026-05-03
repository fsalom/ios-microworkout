import Foundation
import SwiftUI

struct WorkoutLogDetailUiState {
    var log: WorkoutLog
    var expandedNotes: Set<UUID> = []
}

final class WorkoutLogDetailViewModel: ObservableObject {
    @Published var uiState: WorkoutLogDetailUiState

    private let useCase: WorkoutLogUseCaseProtocol

    init(log: WorkoutLog, useCase: WorkoutLogUseCaseProtocol) {
        self.uiState = .init(log: log)
        self.useCase = useCase
        self.uiState.expandedNotes = Set(log.exercises.filter { ($0.notes?.isEmpty == false) }.map { $0.id })
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
}
