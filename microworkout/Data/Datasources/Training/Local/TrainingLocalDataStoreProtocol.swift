protocol TrainingLocalDataSourceProtocol {
    func getCurrentTraining() -> TrainingDTO?
    func saveCurrentTraining(_ training: TrainingDTO)
}
