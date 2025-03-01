protocol TrainingRepositoryProtocol {
    func getTrainings() -> [Training]
    func getCurrentTraining() -> Training?
    func save(_ training: Training)
}
