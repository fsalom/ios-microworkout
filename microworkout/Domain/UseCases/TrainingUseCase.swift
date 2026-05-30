class TrainingUseCase: TrainingUseCaseProtocol {

    private var repository: TrainingRepositoryProtocol

    init(repository: TrainingRepositoryProtocol) {
        self.repository = repository
    }

    func getTrainings() async throws -> [Training] {
        try await self.repository.getTrainings()
    }

    func getCurrent() async throws -> Training? {
        try await self.repository.getCurrent()
    }

    func saveCurrent(_ training: Training) async throws {
        try await self.repository.saveCurrent(training)
    }

    func finish(_ training: Training) async throws {
        try await self.repository.finish(training)
    }

    func getFinished() async throws -> [Training] {
        try await self.repository.getFinished()
    }
}
