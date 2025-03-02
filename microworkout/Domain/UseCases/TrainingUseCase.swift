class TrainingUseCase {

    private var repository: TrainingRepositoryProtocol

    init(repository: TrainingRepositoryProtocol) {
        self.repository = repository
    }

    func getTrainings() -> [Training] {
        self.repository.getTrainings()
    }

    func getCurrentTraining() -> Training? {
        self.repository.getCurrentTraining()
    }

    func save(_ training: Training) {
        self.repository.save(training)
    }
}
