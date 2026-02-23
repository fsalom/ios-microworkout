import Foundation
import Combine

class ListPlanViewModel: ObservableObject {
    @Published var trainings: [Training] = []

    private var cancellable: AnyCancellable?

    init() {
        cancellable = WatchConnectivityManager.shared.$trainings
            .receive(on: RunLoop.main)
            .assign(to: \.trainings, on: self)
        trainings = WatchConnectivityManager.shared.trainings
    }
}
