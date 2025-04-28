class TrainingUseCase {

    private var repository: TrainingRepositoryProtocol

    init(repository: TrainingRepositoryProtocol) {
        self.repository = repository
    }

    func getTrainings() -> [Training] {
        self.repository.getTrainings()
    }

    func getCurrent() -> Training? {
        self.repository.getCurrent()
    }

    func saveCurrent(_ training: Training) {
        self.repository.saveCurrent(training)
    }

    func finish(_ training: Training) {
        self.repository.finish(training)
    }

    func getFinished() -> [Training] {
        self.repository.getFinished()
    }
}
