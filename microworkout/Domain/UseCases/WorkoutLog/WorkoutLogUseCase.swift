import Foundation

class WorkoutLogUseCase: WorkoutLogUseCaseProtocol {
    private let repository: WorkoutLogRepositoryProtocol

    init(repository: WorkoutLogRepositoryProtocol) {
        self.repository = repository
    }

    func getAllSessions() -> [WorkoutSession] { repository.getAllSessions() }
    func saveSession(_ session: WorkoutSession) { repository.saveSession(session) }
    func deleteSession(id: String) { repository.deleteSession(id: id) }

    func getAllLogs() -> [WorkoutLog] { repository.getAllLogs() }
    func saveLog(_ log: WorkoutLog) {
        repository.saveLog(log)
        NotificationCenter.default.post(name: .workoutLogsChanged, object: nil)
    }
    func deleteLog(id: String) {
        repository.deleteLog(id: id)
        NotificationCenter.default.post(name: .workoutLogsChanged, object: nil)
    }

    func getPreviousLoggedExercise(
        sessionId: UUID?,
        exerciseId: UUID,
        beforeLogId: UUID?
    ) -> (exercise: LoggedExercise, date: Date)? {
        guard let sessionId else { return nil }
        let candidates = repository.getAllLogs()
            .filter { $0.sessionId == sessionId && $0.id != beforeLogId }
            .sorted { $0.startedAt > $1.startedAt }
        for log in candidates {
            if let match = log.exercises.first(where: { $0.exercise.id == exerciseId }),
               !match.sets.isEmpty {
                return (match, log.startedAt)
            }
        }
        return nil
    }
}
