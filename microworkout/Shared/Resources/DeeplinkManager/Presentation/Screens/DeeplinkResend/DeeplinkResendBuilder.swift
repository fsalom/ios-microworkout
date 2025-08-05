//
//  Gula
//
//  DeeplinkResendBuilder.swift
//
//  Created by Rudo Apps on 9/5/25
//

final class DeeplinkResendBuilder {
    func build(with config: DeeplinkResendConfig) -> DeeplinkResendView {
        let dataSource = DeeplinkManagerDatasource(network: Config.shared.network)
        let errorHandler = ErrorHandlerManager()
        let repository = DeeplinkManagerRepository(dataSource: dataSource,
                                                   errorHandler: errorHandler)
        let useCase = DeeplinkManagerUseCase(repository: repository)
        let viewModel = DeeplinkResendViewModel(useCase: useCase, config: config)
        let view = DeeplinkResendView(viewModel: viewModel)
        return view
    }
}
