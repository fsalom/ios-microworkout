class MenuRouter {
    private var navigator: NavigatorProtocol

    init(navigator: NavigatorProtocol) {
        self.navigator = navigator
    }

    func goTo(_ destination: MenuDestination) {
        switch destination {
        case .home:
            navigator.push(to: ListPlanBuilder().build())
        case .squatDataCollector:
            navigator.push(to: SquatDataCollectorView())
        }
    }
}
