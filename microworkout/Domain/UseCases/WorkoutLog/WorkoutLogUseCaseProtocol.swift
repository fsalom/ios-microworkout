protocol WorkoutLogUseCaseProtocol {
    func getAllSessions() -> [WorkoutSession]
    func saveSession(_ session: WorkoutSession)
    func deleteSession(id: String)

    func getAllLogs() -> [WorkoutLog]
    func saveLog(_ log: WorkoutLog)
    func deleteLog(id: String)
}
