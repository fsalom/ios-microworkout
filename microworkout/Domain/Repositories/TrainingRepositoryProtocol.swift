protocol TrainingRepositoryProtocol {
    func getTrainings() -> [Training]
    func getCurrent() -> Training?
    func saveCurrent(_ training: Training)
    func finish(_ training: Training)
    func getFinished() -> [Training]
}
