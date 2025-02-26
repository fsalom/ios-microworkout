class TrainingRepository: TrainingRepositoryProtocol {

    private var local: TrainingLocalDataSourceProtocol

    init(local: TrainingLocalDataSourceProtocol) {
        self.local = local
    }

    func getTrainings() -> [Training] {
        return [
            Training(name: "Flexiones", image: "push-up-1",type: .strength, numberOfSets: 10, numberOfReps: 10, numberOfMinutesPerSet: 60),
            Training(name: "Dominadas", image: "pull-up-1", type: .strength, numberOfSets: 10, numberOfReps: 5, numberOfMinutesPerSet: 60),
            Training(name: "Sentadillas", image: "squat-1", type: .strength, numberOfSets: 10, numberOfReps: 20, numberOfMinutesPerSet: 60),
            Training(name: "Abdominales", image: "abs-1", type: .strength, numberOfSets: 10, numberOfReps: 20, numberOfMinutesPerSet: 60)
        ]
    }

    func getCurrentTraining() -> Training? {
        let dto = self.local.getCurrentTraining()
        return dto?.toDomain()
    }
}


fileprivate extension TrainingDTO {
    func toDomain() -> Training {
        return Training(name: self.name, image: self.image, type: .strength, numberOfSets: 10, numberOfReps: 10, numberOfMinutesPerSet: 60)
    }
}

fileprivate extension Training {
    func toDTO() -> TrainingDTO {
        return TrainingDTO(name: self.name,
                           image: self.image,
                           type: self.type,
                           numberOfSetsCompleted: self.numberOfSetsCompleted,
                           numberOfSets: self.numberOfSets,
                           numberOfReps: self.numberOfReps,
                           numberOfMinutesPerSet: self.numberOfMinutesPerSet)
    }
}
