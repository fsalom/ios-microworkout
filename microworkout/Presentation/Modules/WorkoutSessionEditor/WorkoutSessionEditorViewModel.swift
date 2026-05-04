import Foundation
import SwiftUI

struct WorkoutSessionEditorUiState {
    var session: WorkoutSession
    var isNew: Bool
    var isPickingExercise: Bool = false
    var search: String = ""
    var searchResults: [Exercise] = []
    var didSave: Bool = false

    var canSave: Bool {
        !session.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

final class WorkoutSessionEditorViewModel: ObservableObject {
    @Published var uiState: WorkoutSessionEditorUiState

    private let useCase: WorkoutLogUseCaseProtocol
    private let exerciseUseCase: ExerciseUseCaseProtocol
    private var searchTask: Task<Void, Never>?

    init(session: WorkoutSession,
         isNew: Bool,
         useCase: WorkoutLogUseCaseProtocol,
         exerciseUseCase: ExerciseUseCaseProtocol) {
        self.uiState = .init(session: session, isNew: isNew)
        self.useCase = useCase
        self.exerciseUseCase = exerciseUseCase
    }

    func updateName(_ name: String) {
        uiState.session.name = name
    }

    func openPicker() {
        uiState.isPickingExercise = true
        uiState.search = ""
        uiState.searchResults = []
        search("")
    }

    func closePicker() {
        uiState.isPickingExercise = false
    }

    func search(_ text: String) {
        uiState.search = text
        searchTask?.cancel()
        searchTask = Task { @MainActor in
            do {
                let results = try await exerciseUseCase.getAll(contains: text)
                guard !Task.isCancelled else { return }
                self.uiState.searchResults = results.sorted { $0.name.lowercased() < $1.name.lowercased() }
            } catch {
                self.uiState.searchResults = []
            }
        }
    }

    func addExercise(_ exercise: Exercise) {
        guard !uiState.session.exercises.contains(where: { $0.id == exercise.id }) else {
            closePicker()
            return
        }
        uiState.session.exercises.append(exercise)
        closePicker()
    }

    func createAndAdd(named name: String) {
        Task { @MainActor in
            do {
                let exercise = try await exerciseUseCase.create(with: name)
                self.addExercise(exercise)
            } catch {
                print("[Editor] error creating exercise: \(error)")
            }
        }
    }

    func removeExercise(id: UUID) {
        uiState.session.exercises.removeAll { $0.id == id }
    }

    func moveUp(id: UUID) {
        guard let idx = uiState.session.exercises.firstIndex(where: { $0.id == id }), idx > 0 else { return }
        uiState.session.exercises.swapAt(idx, idx - 1)
    }

    func moveDown(id: UUID) {
        guard let idx = uiState.session.exercises.firstIndex(where: { $0.id == id }),
              idx < uiState.session.exercises.count - 1 else { return }
        uiState.session.exercises.swapAt(idx, idx + 1)
    }

    func save() {
        guard uiState.canSave else { return }
        var updated = uiState.session
        updated.updatedAt = Date()
        useCase.saveSession(updated)
        uiState.session = updated
        uiState.didSave = true
    }
}
