import Foundation

class ListPlanBuilder {
    func build() -> ListPlanView {
        let viewModel = ListPlanViewModel()
        let view = ListPlanView(viewModel: viewModel)
        return view
    }
}
