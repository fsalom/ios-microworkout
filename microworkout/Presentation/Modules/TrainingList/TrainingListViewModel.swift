import Foundation
import SwiftUICore

final class TrainingListViewModel: ObservableObject {
    enum TypeOfList {
        case horizontal
        case vertical
    }

    @Published var trainings: [Training] = []
    @Published var typeOfList: TypeOfList = .horizontal
    @Published var selectedTraining: Training = .init(name: "", image: "", type: .strength, numberOfSets: 0, numberOfReps: 0, numberOfMinutesPerSet: 10)

    private var router: TrainingListRouter
    
    init(router: TrainingListRouter) {
        self.router = router
        self.loadTrainings()
    }


    private func loadTrainings() {
        Task {
            await MainActor.run {
                trainings = [
                    Training(name: "Flexiones", image: "push-up-1",type: .strength, numberOfSets: 10, numberOfReps: 10, numberOfMinutesPerSet: 60),
                    Training(name: "Dominadas", image: "pull-up-1", type: .strength, numberOfSets: 10, numberOfReps: 5, numberOfMinutesPerSet: 60),
                    Training(name: "Sentadillas", image: "squat-1", type: .strength, numberOfSets: 10, numberOfReps: 20, numberOfMinutesPerSet: 60),
                    Training(name: "Abdominales", image: "abs-1", type: .strength, numberOfSets: 10, numberOfReps: 20, numberOfMinutesPerSet: 60)
                ]
            }
        }
    }

    func goTo(_ training: Training) {
        router.goTo(training)
    }

    func changeListType() {
        Task {
            await MainActor.run {
                typeOfList = typeOfList == .horizontal ? .vertical : .horizontal
            }
        }
    }
}
