protocol TrainingRepositoryProtocol {
    func getTrainings() -> [Training]
    func getCurrentTraining() -> Training?
}
