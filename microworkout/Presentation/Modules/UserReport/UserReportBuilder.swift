import Foundation

class UserReportBuilder {
    private let component: AppComponentProtocol

    init(component: AppComponentProtocol) {
        self.component = component
    }

    func build() -> UserReportView {
        let viewModel = UserReportViewModel(useCase: component.userReportUseCase)
        return UserReportView(viewModel: viewModel)
    }
}
