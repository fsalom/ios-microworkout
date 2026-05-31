protocol WorkoutLogRepositoryProtocol {
    func getAllSessions() async throws -> [WorkoutSession]
    func saveSession(_ session: WorkoutSession) async throws
    func deleteSession(id: String) async throws

    func getAllLogs() async throws -> [WorkoutLog]
    func saveLog(_ log: WorkoutLog) async throws
    func deleteLog(id: String) async throws
}
