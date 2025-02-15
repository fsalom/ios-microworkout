import Foundation

final class TrainingListViewModel: ObservableObject {
    enum TypeOfList {
        case horizontal
        case vertical
    }

    @Published var trainings: [Training] = []
    @Published var typeOfList: TypeOfList = .horizontal

    private var router: TrainingListRouter
    
    init(router: TrainingListRouter) {
        self.router = router
        self.loadTrainings()
    }


    private func loadTrainings() {
        Task {
            await MainActor.run {
                trainings = [
                    Training(name: "Flexiones", image: "push-up-1",type: .strength, numberOfSets: 10, numberOfReps: 10),
                    Training(name: "Dominadas", image: "pull-up-1", type: .strength, numberOfSets: 10, numberOfReps: 5),
                    Training(name: "Sentadillas", image: "squat-1", type: .strength, numberOfSets: 10, numberOfReps: 20),
                    Training(name: "Abdominales", image: "abs-1", type: .strength, numberOfSets: 10, numberOfReps: 20)
                ]
            }
        }
    }

    func goToWorkout() {
        router.goToWorkoutList()
    }

    func changeListType() {
        Task {
            await MainActor.run {
                typeOfList = typeOfList == .horizontal ? .vertical : .horizontal
            }
        }
    }
}
