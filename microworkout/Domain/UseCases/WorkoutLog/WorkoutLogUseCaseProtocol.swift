import Foundation

protocol WorkoutLogUseCaseProtocol {
    func getAllSessions() -> [WorkoutSession]
    func saveSession(_ session: WorkoutSession)
    func deleteSession(id: String)

    func getAllLogs() -> [WorkoutLog]
    func saveLog(_ log: WorkoutLog)
    func deleteLog(id: String)

    /// Returns the most recent LoggedExercise for `exerciseId` recorded in a log with the same `sessionId`,
    /// excluding the log with id `beforeLogId`, together with that log's start date.
    /// Returns nil if there is no previous occurrence.
    func getPreviousLoggedExercise(sessionId: UUID?, exerciseId: UUID, beforeLogId: UUID?) -> (exercise: LoggedExercise, date: Date)?
}
