protocol WorkoutLogLocalDataSourceProtocol {
    func getAllSessions() -> [WorkoutSessionDTO]
    func saveSession(_ session: WorkoutSessionDTO)
    func deleteSession(id: String)

    func getAllLogs() -> [WorkoutLogDTO]
    func saveLog(_ log: WorkoutLogDTO)
    func deleteLog(id: String)
}
