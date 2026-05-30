import Foundation

class WorkoutLogUseCase: WorkoutLogUseCaseProtocol {
    private let repository: WorkoutLogRepositoryProtocol

    init(repository: WorkoutLogRepositoryProtocol) {
        self.repository = repository
    }

    func getAllSessions() async throws -> [WorkoutSession] {
        try await repository.getAllSessions()
    }

    func saveSession(_ session: WorkoutSession) async throws {
        try await repository.saveSession(session)
    }

    func deleteSession(id: String) async throws {
        try await repository.deleteSession(id: id)
    }

    func getAllLogs() async throws -> [WorkoutLog] {
        try await repository.getAllLogs()
    }

    func saveLog(_ log: WorkoutLog) async throws {
        try await repository.saveLog(log)
        NotificationCenter.default.post(name: .workoutLogsChanged, object: nil)
    }

    func deleteLog(id: String) async throws {
        try await repository.deleteLog(id: id)
        NotificationCenter.default.post(name: .workoutLogsChanged, object: nil)
    }

    func getPreviousLoggedExercise(
        sessionId: UUID?,
        exerciseId: UUID,
        beforeLogId: UUID?
    ) async throws -> (exercise: LoggedExercise, date: Date)? {
        guard let sessionId else { return nil }
        let candidates = try await repository.getAllLogs()
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
