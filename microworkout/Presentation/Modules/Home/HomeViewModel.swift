import Foundation

final class HomeViewModel: ObservableObject {
    @Published var trainings: [Training] = []

    private var router: HomeRouter

    init(router: HomeRouter) {
        self.router = router
        loadTrainings()
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

    func goToTrainings() {
        router.goToWorkoutList()
    }
}
