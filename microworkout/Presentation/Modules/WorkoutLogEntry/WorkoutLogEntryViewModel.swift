import Foundation
import SwiftUI

enum LoggedSetForm: Identifiable, Equatable {
    case new(exerciseLogId: UUID)
    case edit(exerciseLogId: UUID, setId: UUID)

    var id: String {
        switch self {
        case .new(let exId): return "new-\(exId.uuidString)"
        case .edit(let exId, let setId): return "edit-\(exId.uuidString)-\(setId.uuidString)"
        }
    }

    var exerciseLogId: UUID {
        switch self {
        case .new(let exId): return exId
        case .edit(let exId, _): return exId
        }
    }
}

struct WorkoutLogEntryUiState {
    var log: WorkoutLog
    var expandedNotes: Set<UUID> = []
    var activeForm: LoggedSetForm?
    var isFinished: Bool = false
    var isPickingExercise: Bool = false
    var search: String = ""
    var searchResults: [Exercise] = []
    /// Most recent LoggedExercise of the same session for each Exercise.id in this log, with its log date.
    var previousByExerciseId: [UUID: PreviousExerciseReference] = [:]
}

final class WorkoutLogEntryViewModel: ObservableObject {
    @Published var uiState: WorkoutLogEntryUiState

    private let useCase: WorkoutLogUseCaseProtocol
    private let exerciseUseCase: ExerciseUseCaseProtocol
    private let isNew: Bool
    private var searchTask: Task<Void, Never>?

    init(log: WorkoutLog,
         isNew: Bool,
         useCase: WorkoutLogUseCaseProtocol,
         exerciseUseCase: ExerciseUseCaseProtocol) {
        self.uiState = .init(log: log)
        self.isNew = isNew
        self.useCase = useCase
        self.exerciseUseCase = exerciseUseCase
        loadPreviousReferences()
    }

    private func loadPreviousReferences() {
        var map: [UUID: PreviousExerciseReference] = [:]
        for exerciseLog in uiState.log.exercises {
            if let result = useCase.getPreviousLoggedExercise(
                sessionId: uiState.log.sessionId,
                exerciseId: exerciseLog.exercise.id,
                beforeLogId: uiState.log.id
            ) {
                map[exerciseLog.exercise.id] = PreviousExerciseReference(
                    exercise: result.exercise,
                    date: result.date
                )
            }
        }
        uiState.previousByExerciseId = map
    }

    func toggleNotes(for exerciseLogId: UUID) {
        if uiState.expandedNotes.contains(exerciseLogId) {
            uiState.expandedNotes.remove(exerciseLogId)
        } else {
            uiState.expandedNotes.insert(exerciseLogId)
        }
    }

    func updateNotes(exerciseLogId: UUID, notes: String) {
        guard let idx = uiState.log.exercises.firstIndex(where: { $0.id == exerciseLogId }) else { return }
        uiState.log.exercises[idx].notes = notes.isEmpty ? nil : notes
    }

    func openNewSet(for exerciseLogId: UUID) {
        uiState.activeForm = .new(exerciseLogId: exerciseLogId)
    }

    func openEditSet(exerciseLogId: UUID, setId: UUID) {
        uiState.activeForm = .edit(exerciseLogId: exerciseLogId, setId: setId)
    }

    func closeForm() {
        uiState.activeForm = nil
    }

    func saveSet(weight: Double?, reps: Int?, rir: Float?, tags: [SetTag]) {
        guard let form = uiState.activeForm,
              let exIdx = uiState.log.exercises.firstIndex(where: { $0.id == form.exerciseLogId }) else { return }

        switch form {
        case .new:
            uiState.log.exercises[exIdx].sets.append(
                LoggedSet(weight: weight, reps: reps, rir: rir, tags: tags)
            )
        case .edit(_, let setId):
            if let setIdx = uiState.log.exercises[exIdx].sets.firstIndex(where: { $0.id == setId }) {
                var set = uiState.log.exercises[exIdx].sets[setIdx]
                set.weight = weight
                set.reps = reps
                set.rir = rir
                set.tags = tags
                uiState.log.exercises[exIdx].sets[setIdx] = set
            }
        }
        closeForm()
    }

    func deleteSet(exerciseLogId: UUID, setId: UUID) {
        guard let exIdx = uiState.log.exercises.firstIndex(where: { $0.id == exerciseLogId }) else { return }
        uiState.log.exercises[exIdx].sets.removeAll { $0.id == setId }
    }

    /// Copies all sets from the previous session's logged exercise into the current one,
    /// generating new UUIDs so each copy is an independent set the user can edit/delete.
    func copyPreviousSets(for exerciseLogId: UUID) {
        guard let exIdx = uiState.log.exercises.firstIndex(where: { $0.id == exerciseLogId }) else { return }
        let exerciseId = uiState.log.exercises[exIdx].exercise.id
        guard let previous = uiState.previousByExerciseId[exerciseId] else { return }
        let copied = previous.exercise.sets.map { source in
            LoggedSet(weight: source.weight, reps: source.reps, rir: source.rir, tags: source.tags)
        }
        uiState.log.exercises[exIdx].sets.append(contentsOf: copied)
    }

    /// Returns the last set values to pre-fill the form for a new set on a given exercise.
    func lastSet(for exerciseLogId: UUID) -> LoggedSet? {
        uiState.log.exercises.first(where: { $0.id == exerciseLogId })?.sets.last
    }

    /// Returns the set being edited to pre-fill the form.
    func setBeingEdited() -> LoggedSet? {
        guard let form = uiState.activeForm,
              case .edit(let exId, let setId) = form,
              let ex = uiState.log.exercises.first(where: { $0.id == exId }),
              let set = ex.sets.first(where: { $0.id == setId }) else { return nil }
        return set
    }

    /// Returns the exercise associated with the active form.
    func exerciseForActiveForm() -> Exercise? {
        guard let form = uiState.activeForm,
              let ex = uiState.log.exercises.first(where: { $0.id == form.exerciseLogId }) else { return nil }
        return ex.exercise
    }

    func finish() {
        uiState.log.endedAt = Date()
        useCase.saveLog(uiState.log)
        uiState.isFinished = true
    }

    // MARK: - Adding extra exercises to this log only

    func openExercisePicker() {
        uiState.isPickingExercise = true
        uiState.search = ""
        searchExercises("")
    }

    func closeExercisePicker() {
        uiState.isPickingExercise = false
    }

    func searchExercises(_ text: String) {
        uiState.search = text
        searchTask?.cancel()
        searchTask = Task { @MainActor in
            do {
                let results = try await exerciseUseCase.getAll(contains: text)
                guard !Task.isCancelled else { return }
                let existingIds = Set(self.uiState.log.exercises.map { $0.exercise.id })
                self.uiState.searchResults = results
                    .filter { !existingIds.contains($0.id) }
                    .sorted { $0.name.lowercased() < $1.name.lowercased() }
            } catch {
                self.uiState.searchResults = []
            }
        }
    }

    func addExerciseToLog(_ exercise: Exercise) {
        guard !uiState.log.exercises.contains(where: { $0.exercise.id == exercise.id }) else {
            closeExercisePicker()
            return
        }
        uiState.log.exercises.append(LoggedExercise(exercise: exercise))
        if let result = useCase.getPreviousLoggedExercise(
            sessionId: uiState.log.sessionId,
            exerciseId: exercise.id,
            beforeLogId: uiState.log.id
        ) {
            uiState.previousByExerciseId[exercise.id] = PreviousExerciseReference(
                exercise: result.exercise,
                date: result.date
            )
        }
        closeExercisePicker()
    }

    func createAndAddExercise(named name: String) {
        Task { @MainActor in
            do {
                let exercise = try await exerciseUseCase.create(with: name)
                self.addExerciseToLog(exercise)
            } catch {
                print("[LogEntry] error creating exercise: \(error)")
            }
        }
    }
}
