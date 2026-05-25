import Foundation

struct ExerciseTabUiState {
    var weeks: [[HealthDay]] = [[]]
    var workoutItems: [WorkoutItem] = []
    var workoutLogs: [WorkoutLog] = []
    var selectedDay: HealthDay = HealthDay(date: Date())
    var error: String?
    var coachInsight: CoachInsight? = nil
    var isLoadingCoach: Bool = false
}

enum DisplayWorkoutItem: Identifiable {
    case manual(WorkoutEntryByDay)
    case appleWatch(HealthWorkout)
    case linked(entry: WorkoutEntryByDay, watch: HealthWorkout)
    case log(WorkoutLog)
    case linkedLog(log: WorkoutLog, watch: HealthWorkout)

    var id: String {
        switch self {
        case .manual(let e): return "m-\(e.id)"
        case .appleWatch(let w): return "aw-\(w.id)"
        case .linked(let e, let w): return "link-\(e.id)-\(w.id)"
        case .log(let l): return "log-\(l.id.uuidString)"
        case .linkedLog(let l, let w): return "linklog-\(l.id.uuidString)-\(w.id)"
        }
    }

    var sortDate: Date {
        switch self {
        case .manual(let e): return e.parsedDate ?? .distantPast
        case .appleWatch(let w): return w.startDate
        case .linked(_, let w): return w.startDate
        case .log(let l): return l.startedAt
        case .linkedLog(_, let w): return w.startDate
        }
    }
}

final class ExerciseTabViewModel: ObservableObject {
    @Published var uiState: ExerciseTabUiState = .init()
    private let router: ExerciseTabRouter
    private let healthUseCase: HealthUseCaseProtocol
    private let workoutEntryUseCase: WorkoutEntryUseCaseProtocol
    private let workoutLogUseCase: WorkoutLogUseCaseProtocol
    private let coachUseCase: CoachUseCaseProtocol

    init(router: ExerciseTabRouter,
         healthUseCase: HealthUseCaseProtocol,
         workoutEntryUseCase: WorkoutEntryUseCaseProtocol,
         workoutLogUseCase: WorkoutLogUseCaseProtocol,
         coachUseCase: CoachUseCaseProtocol) {
        self.router = router
        self.healthUseCase = healthUseCase
        self.workoutEntryUseCase = workoutEntryUseCase
        self.workoutLogUseCase = workoutLogUseCase
        self.coachUseCase = coachUseCase
    }

    func load() {
        loadWeeks()
        loadWorkouts()
        loadTodayHealth()
        loadCoach()
    }

    private func loadCoach() {
        uiState.isLoadingCoach = true
        Task { @MainActor in
            self.uiState.coachInsight = await coachUseCase.workoutInsight()
            self.uiState.isLoadingCoach = false
        }
    }

    private func loadWeeks() {
        Task {
            do {
                let weeks = try await healthUseCase.getDaysPerWeeksWithHealthInfo(for: 4)
                await MainActor.run { self.uiState.weeks = weeks }
            } catch {
                await MainActor.run { self.uiState.error = "Error cargando salud" }
            }
        }
    }

    private func loadTodayHealth() {
        Task {
            if let today = try? await healthUseCase.getHealthInfoForToday() {
                await MainActor.run { self.uiState.selectedDay = today }
            }
        }
    }

    func selectDay(_ day: HealthDay) {
        uiState.selectedDay = day
    }

    private func loadWorkouts() {
        Task { @MainActor in
            let entries = (try? await workoutEntryUseCase.getAllByDay()) ?? []
            var items: [WorkoutItem] = entries.map { .manual($0) }
            if let aw = try? await healthUseCase.getRecentWorkouts() {
                items += aw.map { .appleWatch($0) }
            }
            items.sort { $0.sortDate > $1.sortDate }
            self.uiState.workoutItems = items
            self.uiState.workoutLogs = workoutLogUseCase.getAllLogs()
        }
    }

    /// Display items for the currently selected day. Manual entries and AppleWatch
    /// workouts that are linked together are merged into a single `.linked` item;
    /// unlinked ones stay independent.
    var workoutsForSelectedDay: [DisplayWorkoutItem] {
        let cal = Calendar.current
        let dayItems = uiState.workoutItems.filter {
            cal.isDate($0.sortDate, inSameDayAs: uiState.selectedDay.date)
        }
        let logsToday = uiState.workoutLogs.filter {
            cal.isDate($0.startedAt, inSameDayAs: uiState.selectedDay.date)
        }

        var entries: [WorkoutEntryByDay] = []
        var watches: [HealthWorkout] = []
        for item in dayItems {
            switch item {
            case .manual(let entry): entries.append(entry)
            case .appleWatch(let watch): watches.append(watch)
            }
        }

        var pairedWatchIds = Set<String>()
        var result: [DisplayWorkoutItem] = []

        for log in logsToday {
            if let linkedId = log.linkedHealthWorkoutId?.uuidString,
               let watch = watches.first(where: { $0.id == linkedId }) {
                result.append(.linkedLog(log: log, watch: watch))
                pairedWatchIds.insert(watch.id)
            } else {
                result.append(.log(log))
            }
        }

        for entry in entries {
            if let watch = watches.first(where: { $0.linkedEntryDate == entry.date }),
               !pairedWatchIds.contains(watch.id) {
                result.append(.linked(entry: entry, watch: watch))
                pairedWatchIds.insert(watch.id)
            } else {
                result.append(.manual(entry))
            }
        }
        for watch in watches where !pairedWatchIds.contains(watch.id) {
            result.append(.appleWatch(watch))
        }

        return result.sorted { $0.sortDate > $1.sortDate }
    }

    func goTo(entryDay: WorkoutEntryByDay) {
        router.goTo(this: entryDay)
    }

    func goToLinked(entry: WorkoutEntryByDay, watch: HealthWorkout) {
        router.goToLinked(entry: entry, watch: watch)
    }

    func goTo(workout: HealthWorkout) {
        router.goToHealthWorkoutDetail(workout)
    }

    func goTo(log: WorkoutLog) {
        router.goToLogDetail(log)
    }

    func goToChat(prompt: String) {
        router.goToChat(prompt: prompt)
    }

    var currentMonthLabel: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_ES")
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: Date()).capitalized
    }
}
