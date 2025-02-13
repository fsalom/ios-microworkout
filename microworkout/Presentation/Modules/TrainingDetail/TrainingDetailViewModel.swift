import Foundation

final class TrainingDetailViewModel: ObservableObject {

    private var router: TrainingDetailRouter

    init(router: TrainingDetailRouter) {
        self.router = router
    }
}
