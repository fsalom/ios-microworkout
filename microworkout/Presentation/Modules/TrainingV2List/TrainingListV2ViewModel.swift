import Foundation
import SwiftUICore

final class TrainingListV2ViewModel: ObservableObject {
    enum TypeOfList {
        case horizontal
        case vertical
    }

    @Published var trainings: [Training] = []
    @Published var typeOfList: TypeOfList = .horizontal
    @Published var selectedTraining: Training = .init(name: "", image: "", type: .strength, numberOfSetsForSlider: 0, numberOfRepsForSlider: 0, numberOfMinutesPerSetForSlider: 10)

    private var router: TrainingListV2Router

    init(router: TrainingListV2Router) {
        self.router = router
        self.loadTrainings()
    }


    private func loadTrainings() {
        Task {
            await MainActor.run {
                trainings = [
                    Training(name: "Flexiones", image: "push-up-1",type: .strength, numberOfSetsForSlider: 10, numberOfRepsForSlider: 10, numberOfMinutesPerSetForSlider: 60),
                    Training(name: "Dominadas", image: "pull-up-1", type: .strength, numberOfSetsForSlider: 10, numberOfRepsForSlider: 5, numberOfMinutesPerSetForSlider: 60),
                    Training(name: "Sentadillas", image: "squat-1", type: .strength, numberOfSetsForSlider: 10, numberOfRepsForSlider: 20, numberOfMinutesPerSetForSlider: 60),
                    Training(name: "Abdominales", image: "abs-1", type: .strength, numberOfSetsForSlider: 10, numberOfRepsForSlider: 20, numberOfMinutesPerSetForSlider: 60)
                ]
            }
        }
    }

    func goTo(_ training: Training, and namespace: Namespace.ID) {
        router.goTo(training, and: namespace)
    }

    func changeListType() {
        Task {
            await MainActor.run {
                typeOfList = typeOfList == .horizontal ? .vertical : .horizontal
            }
        }
    }
}
