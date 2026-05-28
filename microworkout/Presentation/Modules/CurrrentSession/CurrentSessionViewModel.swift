import SwiftUI
import Combine

struct CurrentSessionUiState {
    var searchText: String = ""
    var workoutEntries: [WorkoutEntry] = []
    var exercises: [Exercise] = []
    var availableTrainings: [Training] = []
    var isRunning: Bool = false
    var isSaved: Bool = false
    var startTime: Date? = nil
    var now: Date = Date()
    var activeForm: CurrentSessionViewModel.ActiveExerciseForm?
    var suggestedAWWorkout: HealthWorkout?
}

class CurrentSessionViewModel: ObservableObject {
    @Published var uiState = CurrentSessionUiState()

    let mirrorManager = WorkoutMirrorManager.shared

    private var exerciseUseCase: ExerciseUseCaseProtocol
    private var workoutEntryUseCase: WorkoutEntryUseCaseProtocol
    private var healthUseCase: HealthUseCaseProtocol
    private var trainingUseCase: TrainingUseCaseProtocol
    private var cancellables = Set<AnyCancellable>()

    init(exerciseUseCase: ExerciseUseCaseProtocol,
         workoutEntryUseCase: WorkoutEntryUseCaseProtocol,
         healthUseCase: HealthUseCaseProtocol,
         trainingUseCase: TrainingUseCaseProtocol) {
        self.exerciseUseCase = exerciseUseCase
        self.workoutEntryUseCase = workoutEntryUseCase
        self.healthUseCase = healthUseCase
        self.trainingUseCase = trainingUseCase

        mirrorManager.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)

        // searchText cambia → buscar ejercicios. Antes vivía como didSet del @Published;
        // se mueve aquí para mantener el patrón uiState.
        $uiState
            .map(\.searchText)
            .removeDuplicates()
            .dropFirst()
            .sink { [weak self] text in self?.search(with: text) }
            .store(in: &cancellables)

        Task { @MainActor [weak self] in
            guard let self else { return }
            self.uiState.availableTrainings = (try? await self.trainingUseCase.getTrainings()) ?? []
        }
    }

    enum ActiveExerciseForm: Identifiable {
        case new(Exercise)
        case edit(WorkoutEntry)

        var id: UUID {
            switch self {
            case .new(let exercise): return exercise.id
            case .edit(let logged): return logged.id
            }
        }
    }

    func search(with text: String) {
        Task { @MainActor in
            do {
                self.uiState.exercises = try await self.exerciseUseCase.getAll(contains: text)
            } catch {
                print("Failed to fetch exercises: \(error)")
                self.uiState.exercises = []
            }
        }
    }

    func startSession() {
        uiState.startTime = Date()
        uiState.isRunning = true
    }

    func secondsBetween(_ start: Date, _ end: Date) -> Int {
        return Int(end.timeIntervalSince(start))
    }

    func stopSession() {
        let sessionStart = uiState.startTime
        Task { @MainActor in
            if let sessionStart = sessionStart {
                let sessionEnd = Date()
                if let workouts = try? await healthUseCase.getRecentWorkouts() {
                    let overlapping = workouts.first { workout in
                        workout.linkedTrainingID == nil &&
                        workout.startDate < sessionEnd &&
                        workout.endDate > sessionStart
                    }
                    uiState.suggestedAWWorkout = overlapping
                }
            }
            uiState.startTime = nil
            uiState.workoutEntries.removeAll()
            uiState.isSaved = true
            uiState.isRunning = false
        }
    }

    func updateNow(to date: Date) {
        uiState.now = date
    }

    func addExercise(with name: String) {
        Task { @MainActor in
            let exercise = try await self.exerciseUseCase.create(with: name)
            uiState.searchText = ""
            uiState.activeForm = .new(exercise)
        }
    }

    func addWorkoutEntry(_ new: WorkoutEntry) {
        Task { @MainActor in
            try await workoutEntryUseCase.add(new)
            uiState.workoutEntries = reorder(uiState.workoutEntries + [new])
            uiState.activeForm = nil
        }
    }

    func updateWorkoutEntry(_ updated: WorkoutEntry) {
        Task { @MainActor in
            try await workoutEntryUseCase.update(updated)
            if let idx = uiState.workoutEntries.firstIndex(where: { $0.id == updated.id }) {
                uiState.workoutEntries[idx] = updated
            }
            uiState.workoutEntries = reorder(uiState.workoutEntries)
            uiState.activeForm = nil
        }
    }

    func deleteEntries(with ids: [UUID]) {
        Task { @MainActor in
            for id in ids {
                try await workoutEntryUseCase.delete(entryID: id)
                uiState.workoutEntries.removeAll { $0.id == id }
            }
        }
    }

    func createWorkoutEntry(from last: WorkoutEntry) -> WorkoutEntry {
        WorkoutEntry(exercise: last.exercise, reps: last.reps, weight: last.weight)
    }

    func getWorkoutEntry(for exercise: Exercise) -> WorkoutEntry {
        guard let last = uiState.workoutEntries.last(where: { $0.exercise == exercise }) else {
            return createWorkoutEntry(from: .init(exercise: exercise, reps: nil, weight: nil))
        }
        return createWorkoutEntry(from: last)
    }

    func toggleCompletion(for entryId: UUID) {
        if let index = uiState.workoutEntries.firstIndex(where: { $0.id == entryId }) {
            uiState.workoutEntries[index].isCompleted.toggle()
        }
    }

    func groupedByExercise() -> [Exercise: [WorkoutEntry]] {
        workoutEntryUseCase.groupByExercise(these: uiState.workoutEntries)
    }

    func orderedExercises() -> [Exercise] {
        workoutEntryUseCase.order(these: uiState.workoutEntries)
    }

    func action(for grouped: [Exercise: [WorkoutEntry]], and exercise: Exercise) {
        if let last = grouped[exercise]?.last {
            let new = createWorkoutEntry(from: last)
            uiState.activeForm = .new(new.exercise)
        } else {
            let new = WorkoutEntry(exercise: exercise, reps: 0, weight: 0)
            uiState.activeForm = .edit(new)
        }
    }

    func reorder(_ entries: [WorkoutEntry]) -> [WorkoutEntry] {
        entries.sorted { $0.date > $1.date }
    }

    func getAvailableTrainings() -> [Training] {
        uiState.availableTrainings
    }

    func linkAWWorkout(_ workout: HealthWorkout, to training: Training) {
        healthUseCase.linkWorkout(workout.id, to: training.id)
        uiState.suggestedAWWorkout = nil
    }

    func dismissAWSuggestion() {
        uiState.suggestedAWWorkout = nil
    }
}
