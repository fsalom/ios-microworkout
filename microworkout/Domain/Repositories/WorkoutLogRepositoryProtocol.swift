protocol WorkoutLogRepositoryProtocol {
    func getAllSessions() async throws -> [WorkoutSession]
    func saveSession(_ session: WorkoutSession) async throws
    func deleteSession(id: String) async throws

    func getAllLogs() async throws -> [WorkoutLog]
    func saveLog(_ log: WorkoutLog) async throws
    func deleteLog(id: String) async throws
    /// Cuántas sesiones + registros locales todavía no están en la cuenta.
    func pendingSyncCount() async throws -> Int
    /// Sube a la cuenta las sesiones y registros locales que aún no estén en el
    /// servidor (modelo espejo: no borra la copia local). Devuelve cuántos subió.
    func syncLocalToRemote() async throws -> Int
}
