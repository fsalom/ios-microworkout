import Foundation
import SwiftUI

struct PreviousExerciseReference: Equatable {
    let exercise: LoggedExercise
    let date: Date
}

struct WorkoutLogDetailUiState {
    var log: WorkoutLog
    var expandedNotes: Set<UUID> = []
    var linkedHealthWorkout: HealthWorkout? = nil
    /// Most recent LoggedExercise of the same session for each Exercise.id in this log, with its log date.
    var previousByExerciseId: [UUID: PreviousExerciseReference] = [:]
    /// All logs sharing the same `sessionId` as the current log, sorted by `startedAt` ascending.
    /// Empty if the current log has no `sessionId` or it's the only one.
    var siblingLogs: [WorkoutLog] = []
    /// Index of the currently displayed log within `siblingLogs`. -1 if no siblings.
    var currentSiblingIndex: Int = -1
    /// When non-nil, presents the media gallery sheet for that set id.
    var mediaSheetSetId: UUID? = nil
}

extension WorkoutLogDetailUiState {
    var canGoBack: Bool { currentSiblingIndex > 0 }
    var canGoForward: Bool {
        currentSiblingIndex >= 0 && currentSiblingIndex < siblingLogs.count - 1
    }
    var hasSiblings: Bool { siblingLogs.count > 1 }
}

final class WorkoutLogDetailViewModel: ObservableObject {
    @Published var uiState: WorkoutLogDetailUiState

    private let useCase: WorkoutLogUseCaseProtocol
    private let healthUseCase: HealthUseCaseProtocol
    private let router: WorkoutLogDetailRouter
    let mediaUseCase: SetMediaUseCase

    init(log: WorkoutLog,
         useCase: WorkoutLogUseCaseProtocol,
         healthUseCase: HealthUseCaseProtocol,
         router: WorkoutLogDetailRouter,
         mediaUseCase: SetMediaUseCase) {
        self.uiState = .init(log: log)
        self.useCase = useCase
        self.healthUseCase = healthUseCase
        self.router = router
        self.mediaUseCase = mediaUseCase
        loadSiblings()
        loadDerivedState()
    }

    func goToEdit() {
        router.goToEdit(log: uiState.log)
    }

    func goToProgression(sourceSetId: UUID) {
        router.goToProgression(sourceSetId: sourceSetId)
    }

    func openMediaGallery(setId: UUID) {
        uiState.mediaSheetSetId = setId
    }

    func closeMediaGallery() {
        uiState.mediaSheetSetId = nil
    }

    /// Re-fetches the current log from storage. Useful after returning from edit.
    func reloadFromStorage() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            let logs = (try? await self.useCase.getAllLogs()) ?? []
            guard let updated = logs.first(where: { $0.id == self.uiState.log.id }) else { return }
            self.uiState.log = updated
            if self.uiState.currentSiblingIndex >= 0 {
                self.uiState.siblingLogs = logs
                    .filter { $0.sessionId == updated.sessionId }
                    .sorted { $0.startedAt < $1.startedAt }
                self.uiState.currentSiblingIndex = self.uiState.siblingLogs.firstIndex(where: { $0.id == updated.id }) ?? -1
            }
            self.loadDerivedState()
        }
    }

    private func loadSiblings() {
        guard let sessionId = uiState.log.sessionId else {
            uiState.siblingLogs = []
            uiState.currentSiblingIndex = -1
            return
        }
        Task { @MainActor [weak self] in
            guard let self else { return }
            let logs = (try? await self.useCase.getAllLogs()) ?? []
            let siblings = logs
                .filter { $0.sessionId == sessionId }
                .sorted { $0.startedAt < $1.startedAt }
            self.uiState.siblingLogs = siblings
            self.uiState.currentSiblingIndex = siblings.firstIndex(where: { $0.id == self.uiState.log.id }) ?? -1
        }
    }

    private func loadDerivedState() {
        uiState.expandedNotes = Set(
            uiState.log.exercises
                .filter { ($0.notes?.isEmpty == false) }
                .map { $0.id }
        )
        uiState.linkedHealthWorkout = nil
        loadPreviousReferences()
        loadLinkedHealthWorkout()
    }

    private func loadPreviousReferences() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            var map: [UUID: PreviousExerciseReference] = [:]
            for exerciseLog in self.uiState.log.exercises {
                if let result = try? await self.useCase.getPreviousLoggedExercise(
                    sessionId: self.uiState.log.sessionId,
                    exerciseId: exerciseLog.exercise.id,
                    beforeLogId: self.uiState.log.id
                ) {
                    map[exerciseLog.exercise.id] = PreviousExerciseReference(
                        exercise: result.exercise,
                        date: result.date
                    )
                }
            }
            self.uiState.previousByExerciseId = map
        }
    }

    func goToPreviousSibling() {
        guard uiState.canGoBack else { return }
        switchTo(index: uiState.currentSiblingIndex - 1)
    }

    func goToNextSibling() {
        guard uiState.canGoForward else { return }
        switchTo(index: uiState.currentSiblingIndex + 1)
    }

    private func switchTo(index: Int) {
        guard uiState.siblingLogs.indices.contains(index) else { return }
        uiState.currentSiblingIndex = index
        uiState.log = uiState.siblingLogs[index]
        loadDerivedState()
    }

    func delete() -> Bool {
        let id = uiState.log.id.uuidString
        Task { try? await useCase.deleteLog(id: id) }
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
