class TrainingRepository: TrainingRepositoryProtocol {
    private var local: TrainingLocalDataSourceProtocol

    init(local: TrainingLocalDataSourceProtocol) {
        self.local = local
    }

    func getTrainings() -> [Training] {
        return [
            Training(name: "Flexiones", image: "push-up-1",type: .strength, numberOfSetsForSlider: 10, numberOfRepsForSlider: 10, numberOfMinutesPerSetForSlider: 1),
            Training(name: "Dominadas", image: "pull-up-1", type: .strength, numberOfSetsForSlider: 10, numberOfRepsForSlider: 5, numberOfMinutesPerSetForSlider: 60),
            Training(name: "Sentadillas", image: "squat-1", type: .strength, numberOfSetsForSlider: 10, numberOfRepsForSlider: 20, numberOfMinutesPerSetForSlider: 60),
            Training(name: "Abdominales", image: "abs-1", type: .strength, numberOfSetsForSlider: 10, numberOfRepsForSlider: 20, numberOfMinutesPerSetForSlider: 60)
        ]
    }

    func getCurrent() -> Training? {
        let dto = self.local.getCurrent()
        return dto?.toDomain()
    }

    func saveCurrent(_ training: Training) {
        self.local.saveCurrent(training.toDTO())
    }

    func finish(_ training: Training) {
        self.local.finish(training.toDTO())
    }

    func getFinished() -> [Training] {
        return self.local.getFinished().map { $0.toDomain() }
    }
}

fileprivate extension TrainingDTO {
    func toDomain() -> Training {
        return Training(name: self.name,
                        image: self.image,
                        type: self.type,
                        startedAt: self.startedAt,
                        completedAt: self.completedAt,
                        sets: self.sets,
                        numberOfSetsForSlider: self.numberOfSets,
                        numberOfRepsForSlider: self.numberOfReps,
                        numberOfMinutesPerSetForSlider: self.numberOfMinutesPerSet)
    }
}

fileprivate extension Training {
    func toDTO() -> TrainingDTO {
        return TrainingDTO(
            id: self.id,
            name: self.name,
            image: self.image,
            type: self.type,
            startedAt: self.startedAt,
            completedAt: self.completedAt,
            sets: self.sets,
            numberOfSetsCompleted: self.numberOfSetsCompleted,
            numberOfSets: self.numberOfSetsForSlider,
            numberOfReps: self.numberOfRepsForSlider,
            numberOfMinutesPerSet: self.numberOfMinutesPerSetForSlider
        )
    }
}
