import Foundation

final class MenuViewModel: ObservableObject {
    @Published var menuOptions: [MenuItem] = []
    private var menuRouter: MenuRouter

    init(router: MenuRouter) {
        menuRouter = router
        loadMenuItems()
    }


    private func loadMenuItems() {
        self.menuOptions = [
            MenuItem(title: "Home", destination: .home),
            MenuItem(title: "ML de Squats ", destination: .squatDataCollector),
        ]
    }

    func goTo(_ destination: MenuDestination) {
        menuRouter.goTo(destination)
    }
}
