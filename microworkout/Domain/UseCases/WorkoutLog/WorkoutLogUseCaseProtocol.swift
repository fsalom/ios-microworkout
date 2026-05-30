import Foundation

protocol WorkoutLogUseCaseProtocol {
    func getAllSessions() async throws -> [WorkoutSession]
    func saveSession(_ session: WorkoutSession) async throws
    func deleteSession(id: String) async throws

    func getAllLogs() async throws -> [WorkoutLog]
    func saveLog(_ log: WorkoutLog) async throws
    func deleteLog(id: String) async throws

    /// Returns the most recent LoggedExercise for `exerciseId` recorded in a log with the same `sessionId`,
    /// excluding the log with id `beforeLogId`, together with that log's start date.
    /// Returns nil if there is no previous occurrence.
    func getPreviousLoggedExercise(sessionId: UUID?, exerciseId: UUID, beforeLogId: UUID?) async throws -> (exercise: LoggedExercise, date: Date)?
}
