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
}
