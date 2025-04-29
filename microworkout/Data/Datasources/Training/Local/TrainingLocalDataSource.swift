class TrainingLocalDataSource: TrainingLocalDataSourceProtocol {
    private var localStorage: UserDefaultsManagerProtocol

    enum TrainingKey: String {
        case current
        case finish
    }

    init(localStorage: UserDefaultsManagerProtocol) {
        self.localStorage = localStorage
    }

    func getCurrent() -> TrainingDTO? {
        return self.localStorage.get(forKey: TrainingKey.current.rawValue)
    }

    func saveCurrent(_ training: TrainingDTO) {
        self.localStorage.remove(forKey: TrainingKey.current.rawValue)
        self.localStorage.save(training, forKey: TrainingKey.current.rawValue)
    }

    func finish(_ training: TrainingDTO) {
        var finishedTrainings: [TrainingDTO] = self.localStorage.get(forKey: TrainingKey.finish.rawValue) ?? []
        finishedTrainings.append(training)
        self.localStorage.save(finishedTrainings, forKey: TrainingKey.finish.rawValue)
        self.localStorage.remove(forKey: TrainingKey.current.rawValue)
    }

    func getFinished() -> [TrainingDTO] {
        return self.localStorage.get(forKey: TrainingKey.finish.rawValue) ?? []
    }
}
