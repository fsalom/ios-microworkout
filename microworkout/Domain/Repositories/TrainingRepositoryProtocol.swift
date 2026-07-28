protocol TrainingRepositoryProtocol {
    func getTrainings() async throws -> [Training]
    func getCurrent() async throws -> Training?
    func saveCurrent(_ training: Training) async throws
    func finish(_ training: Training) async throws
    func getFinished() async throws -> [Training]
    /// Cuántos entrenamientos locales todavía no están en la cuenta.
    func pendingSyncCount() async throws -> Int
    /// Sube a la cuenta los entrenamientos locales que aún no estén en el
    /// servidor (modelo espejo: no borra la copia local). Devuelve cuántos subió.
    func syncLocalToRemote() async throws -> Int
}
