class TrainingLocalDataSource: TrainingLocalDataSourceProtocol {
    private var localStorage: UserDefaultsManagerProtocol

    enum TrainingKey: String {
        case currentTraining
    }

    init(localStorage: UserDefaultsManagerProtocol) {
        self.localStorage = localStorage
    }

    func getCurrentTraining() -> TrainingDTO? {
        return self.localStorage.get(forKey: TrainingKey.currentTraining.rawValue)
    }

    func saveCurrentTraining(_ training: TrainingDTO) {
        self.localStorage.save(training, forKey: TrainingKey.currentTraining.rawValue)
    }
}
