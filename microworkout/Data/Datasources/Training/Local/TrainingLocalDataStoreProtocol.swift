protocol TrainingLocalDataSourceProtocol {
    func getCurrent() -> TrainingDTO?
    func saveCurrent(_ training: TrainingDTO)
    func finish(_ training: TrainingDTO)
}
