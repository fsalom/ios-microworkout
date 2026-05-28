import Foundation

struct HealthWorkoutDetailUiState {
    var workout: HealthWorkout
    var availableTrainings: [Training] = []
    var availableEntries: [WorkoutEntryByDay] = []
    var availableLogs: [WorkoutLog] = []
    var linkedTraining: Training? = nil
    var linkedEntry: WorkoutEntryByDay? = nil
    var linkedLog: WorkoutLog? = nil
}

final class HealthWorkoutDetailViewModel: ObservableObject {
    @Published var uiState: HealthWorkoutDetailUiState

    private var router: HealthWorkoutDetailRouter
    private var healthUseCase: HealthUseCaseProtocol
    private var trainingUseCase: TrainingUseCaseProtocol
    private var workoutEntryUseCase: WorkoutEntryUseCaseProtocol
    private var workoutLogUseCase: WorkoutLogUseCaseProtocol

    init(workout: HealthWorkout,
         router: HealthWorkoutDetailRouter,
         healthUseCase: HealthUseCaseProtocol,
         trainingUseCase: TrainingUseCaseProtocol,
         workoutEntryUseCase: WorkoutEntryUseCaseProtocol,
         workoutLogUseCase: WorkoutLogUseCaseProtocol) {
        self.router = router
        self.healthUseCase = healthUseCase
        self.trainingUseCase = trainingUseCase
        self.workoutEntryUseCase = workoutEntryUseCase
        self.workoutLogUseCase = workoutLogUseCase
        self.uiState = HealthWorkoutDetailUiState(workout: workout)
        loadLinkOptions()
    }

    func openLinkedEntry() {
        guard let entry = uiState.linkedEntry else { return }
        router.goTo(entry: entry)
    }

    private func loadLinkOptions() {
        Task { @MainActor in
            let allTrainings = (try? await trainingUseCase.getTrainings()) ?? []
            let recentWorkouts = (try? await healthUseCase.getRecentWorkouts()) ?? []

            // Refresh the link state of OUR workout from the latest data source values,
            // in case the workout was linked in a previous session and the cached object
            // we received in init didn't have the link populated.
            if let fresh = recentWorkouts.first(where: { $0.id == self.uiState.workout.id }) {
                self.uiState.workout.linkedTrainingID = fresh.linkedTrainingID
                self.uiState.workout.linkedEntryDate = fresh.linkedEntryDate
            }

            // Resolve linked training (if any) — search the full list so we can show the
            // current link even if it doesn't match the day filter.
            if let linkedID = self.uiState.workout.linkedTrainingID {
                self.uiState.linkedTraining = allTrainings.first { $0.id == linkedID }
            } else {
                self.uiState.linkedTraining = nil
            }

            // IDs already linked to OTHER Apple Watch workouts; we exclude these from suggestions.
            let trainingsLinkedElsewhere: Set<UUID> = Set(
                recentWorkouts
                    .filter { $0.id != self.uiState.workout.id }
                    .compactMap { $0.linkedTrainingID }
            )
            let entryDatesLinkedElsewhere: Set<String> = Set(
                recentWorkouts
                    .filter { $0.id != self.uiState.workout.id }
                    .compactMap { $0.linkedEntryDate }
            )

            let cal = Calendar.current
            let workoutDay = self.uiState.workout.startDate

            // Trainings: completed today + not linked elsewhere
            self.uiState.availableTrainings = allTrainings.filter { training in
                guard let completedAt = training.completedAt else { return false }
                guard cal.isDate(completedAt, inSameDayAs: workoutDay) else { return false }
                return !trainingsLinkedElsewhere.contains(training.id)
            }

            // Entries: same day, not already linked elsewhere
            let allEntries = (try? await self.workoutEntryUseCase.getAllByDay()) ?? []
            self.uiState.availableEntries = allEntries.filter { entry in
                guard let entryDate = entry.parsedDate else { return false }
                guard cal.isDate(entryDate, inSameDayAs: workoutDay) else { return false }
                return !entryDatesLinkedElsewhere.contains(entry.date)
            }

            // Resolve linked entry if any
            if let linkedDate = self.uiState.workout.linkedEntryDate {
                self.uiState.linkedEntry = allEntries.first { $0.date == linkedDate }
            } else {
                self.uiState.linkedEntry = nil
            }

            // WorkoutLogs: those linking to THIS workout, plus logs from same day not linked elsewhere.
            let allLogs = (try? await self.workoutLogUseCase.getAllLogs()) ?? []
            let workoutUUID = UUID(uuidString: self.uiState.workout.id)

            self.uiState.linkedLog = allLogs.first { $0.linkedHealthWorkoutId == workoutUUID }

            self.uiState.availableLogs = allLogs.filter { log in
                guard cal.isDate(log.startedAt, inSameDayAs: workoutDay) else { return false }
                if let linked = log.linkedHealthWorkoutId {
                    // Only show if not linked or linked to THIS workout (then it's the linked one)
                    return linked == workoutUUID
                }
                return true
            }.filter { $0.linkedHealthWorkoutId == nil }
        }
    }

    func linkTo(training: Training) {
        healthUseCase.linkWorkout(uiState.workout.id, to: training.id)
        uiState.workout.linkedTrainingID = training.id
        uiState.linkedTraining = training
    }

    func unlinkTraining() {
        healthUseCase.unlinkWorkout(uiState.workout.id)
        uiState.workout.linkedTrainingID = nil
        uiState.linkedTraining = nil
    }

    func linkTo(entry: WorkoutEntryByDay) {
        healthUseCase.linkWorkout(uiState.workout.id, toEntryDate: entry.date)
        uiState.workout.linkedEntryDate = entry.date
        uiState.linkedEntry = entry
    }

    func unlinkEntry() {
        healthUseCase.unlinkEntryFromWorkout(uiState.workout.id)
        uiState.workout.linkedEntryDate = nil
        uiState.linkedEntry = nil
    }

    func linkTo(log: WorkoutLog) {
        guard let uuid = UUID(uuidString: uiState.workout.id) else { return }
        var updated = log
        updated.linkedHealthWorkoutId = uuid
        Task { try? await workoutLogUseCase.saveLog(updated) }
        uiState.linkedLog = updated
        uiState.availableLogs.removeAll { $0.id == updated.id }
    }

    func unlinkLog() {
        guard var current = uiState.linkedLog else { return }
        current.linkedHealthWorkoutId = nil
        let snapshot = current
        Task { try? await workoutLogUseCase.saveLog(snapshot) }
        uiState.linkedLog = nil
        uiState.availableLogs.append(current)
        uiState.availableLogs.sort { $0.startedAt > $1.startedAt }
    }

    func openLinkedLog() {
        guard let log = uiState.linkedLog else { return }
        router.goTo(log: log)
    }
}
