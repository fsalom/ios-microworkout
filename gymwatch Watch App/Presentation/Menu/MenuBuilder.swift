class MenuBuilder {
    func build() -> MenuView {
        let viewModel = MenuViewModel(router: MenuRouter(navigator: Navigator.shared))
        return MenuView(viewModel: viewModel)
    }
}
