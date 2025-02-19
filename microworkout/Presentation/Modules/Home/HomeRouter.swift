class HomeRouter {
    private var navigator: NavigatorProtocol

    init(navigator: NavigatorProtocol) {
        self.navigator = navigator
    }

    func goToWorkoutList() {
        navigator.push(to: TrainingListBuilder().build())
    }

    func goToStart(this training: Training) {
        navigator.push(to: TrainingDetailBuilder().build(this: training))
    }
}
