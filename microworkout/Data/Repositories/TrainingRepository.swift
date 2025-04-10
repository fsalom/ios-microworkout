class TrainingRepository: TrainingRepositoryProtocol {

    private var local: TrainingLocalDataSourceProtocol

    init(local: TrainingLocalDataSourceProtocol) {
        self.local = local
    }

    func getTrainings() -> [Training] {
        return [
            Training(name: "Flexiones", image: "push-up-1",type: .strength, numberOfSetsForSlider: 10, numberOfRepsForSlider: 10, numberOfMinutesPerSetForSlider: 60),
            Training(name: "Dominadas", image: "pull-up-1", type: .strength, numberOfSetsForSlider: 10, numberOfRepsForSlider: 5, numberOfMinutesPerSetForSlider: 60),
            Training(name: "Sentadillas", image: "squat-1", type: .strength, numberOfSetsForSlider: 10, numberOfRepsForSlider: 20, numberOfMinutesPerSetForSlider: 60),
            Training(name: "Abdominales", image: "abs-1", type: .strength, numberOfSetsForSlider: 10, numberOfRepsForSlider: 20, numberOfMinutesPerSetForSlider: 60)
        ]
    }

    func getCurrentTraining() -> Training? {
        let dto = self.local.getCurrentTraining()
        return dto?.toDomain()
    }

    func save(_ training: Training) {
        self.local.saveCurrentTraining(training.toDTO())
    }
}


fileprivate extension TrainingDTO {
    func toDomain() -> Training {
        return Training(name: self.name, image: self.image, type: .strength, numberOfSetsForSlider: 10, numberOfRepsForSlider: 10, numberOfMinutesPerSetForSlider: 60)
    }
}

fileprivate extension Training {
    func toDTO() -> TrainingDTO {
        return TrainingDTO(name: self.name,
                           image: self.image,
                           type: self.type,
                           numberOfSetsCompleted: self.numberOfSetsCompleted,
                           numberOfSets: self.numberOfSetsForSlider,
                           numberOfReps: self.numberOfRepsForSlider,
                           numberOfMinutesPerSet: self.numberOfMinutesPerSetForSlider)
    }
}
