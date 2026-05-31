protocol TrainingRepositoryProtocol {
    func getTrainings() async throws -> [Training]
    func getCurrent() async throws -> Training?
    func saveCurrent(_ training: Training) async throws
    func finish(_ training: Training) async throws
    func getFinished() async throws -> [Training]
}
