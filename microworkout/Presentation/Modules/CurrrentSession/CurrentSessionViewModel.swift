import SwiftUI
import Combine

class CurrentSessionViewModel: ObservableObject {
    @Published var searchText: String = "" {
        didSet {
            search(with: self.searchText)
        }
    }
    @Published var workoutEntries: [WorkoutEntry] = []
    @Published var exercises: [Exercise] = []
    @Published var isRunning: Bool = false
    @Published var isSaved: Bool = false
    @Published var startTime: Date? = nil
    @Published var now: Date = Date()
    @Published var activeForm: ActiveExerciseForm?
    @Published var suggestedAWWorkout: HealthWorkout?

    private var exerciseUseCase: ExerciseUseCaseProtocol
    private var workoutEntryUseCase: WorkoutEntryUseCaseProtocol
    private var healthUseCase: HealthUseCaseProtocol
    private var trainingUseCase: TrainingUseCase

    init(exerciseUseCase: ExerciseUseCaseProtocol,
         workoutEntryUseCase: WorkoutEntryUseCaseProtocol,
         healthUseCase: HealthUseCaseProtocol,
         trainingUseCase: TrainingUseCase) {
        self.exerciseUseCase = exerciseUseCase
        self.workoutEntryUseCase = workoutEntryUseCase
        self.healthUseCase = healthUseCase
        self.trainingUseCase = trainingUseCase
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
            self.exercises = try! await self.exerciseUseCase.getAll(contains: self.searchText)
        }
    }

    func startSession() {
        startTime = Date()
        isRunning = true
    }

    func secondsBetween(_ start: Date, _ end: Date) -> Int {
        return Int(end.timeIntervalSince(start))
    }

    func stopSession() {
        let sessionStart = startTime
        Task { @MainActor in
            if let sessionStart = sessionStart {
                let sessionEnd = Date()
                if let workouts = try? await healthUseCase.getRecentWorkouts() {
                    let overlapping = workouts.first { workout in
                        workout.linkedTrainingID == nil &&
                        workout.startDate < sessionEnd &&
                        workout.endDate > sessionStart
                    }
                    suggestedAWWorkout = overlapping
                }
            }
            startTime = nil
            workoutEntries.removeAll()
            isSaved = true
            isRunning = false
        }
    }

    func updateNow(to date: Date) {
        now = date
    }

    func addExercise(with name: String) {
        Task { @MainActor in
            let exercise = try await self.exerciseUseCase.create(with: name)
            searchText = ""
            activeForm = .new(exercise)
        }
    }

    func addWorkoutEntry(_ new: WorkoutEntry) {
        Task { @MainActor in
            try await workoutEntryUseCase.add(new)
            workoutEntries = reorder(workoutEntries + [new])
            activeForm = nil
        }
    }

    func updateWorkoutEntry(_ updated: WorkoutEntry) {
        Task { @MainActor in
            try await workoutEntryUseCase.update(updated)
            if let idx = workoutEntries.firstIndex(where: { $0.id == updated.id }) {
                workoutEntries[idx] = updated
            }
            workoutEntries = reorder(workoutEntries)
            activeForm = nil
        }
    }

    func deleteEntries(with ids: [UUID]) {
        Task { @MainActor in
            for id in ids {
                try await workoutEntryUseCase.delete(entryID: id)
                workoutEntries.removeAll { $0.id == id }
            }
        }
    }

    func createWorkoutEntry(from last: WorkoutEntry) -> WorkoutEntry {
        WorkoutEntry(exercise: last.exercise, reps: last.reps, weight: last.weight)
    }

    func getWorkoutEntry(for exercise: Exercise) -> WorkoutEntry {
        guard let last = workoutEntries.last(where: { $0.exercise == exercise }) else {
            return createWorkoutEntry(from: .init(exercise: exercise, reps: nil, weight: nil))
        }
        return createWorkoutEntry(from: last)
    }

    func toggleCompletion(for entryId: UUID) {
        if let index = workoutEntries.firstIndex(where: { $0.id == entryId }) {
            workoutEntries[index].isCompleted.toggle()
        }
    }

    func groupedByExercise() -> [Exercise: [WorkoutEntry]] {
        workoutEntryUseCase.groupByExercise(these: workoutEntries)
    }

    func orderedExercises() -> [Exercise] {
        workoutEntryUseCase.order(these: workoutEntries)
    }


    func action(for grouped: [Exercise: [WorkoutEntry]], and exercise: Exercise) {
        if let last = grouped[exercise]?.last {
            let new = createWorkoutEntry(from: last)
            activeForm = .new(new.exercise)
        } else {
            let new = WorkoutEntry(exercise: exercise, reps: 0, weight: 0)
            activeForm = .edit(new)
        }
    }

    func reorder(_ entries: [WorkoutEntry]) -> [WorkoutEntry] {
        entries.sorted { $0.date > $1.date }
    }

    func getAvailableTrainings() -> [Training] {
        trainingUseCase.getTrainings()
    }

    func linkAWWorkout(_ workout: HealthWorkout, to training: Training) {
        healthUseCase.linkWorkout(workout.id, to: training.id)
        suggestedAWWorkout = nil
    }

    func dismissAWSuggestion() {
        suggestedAWWorkout = nil
    }
}
