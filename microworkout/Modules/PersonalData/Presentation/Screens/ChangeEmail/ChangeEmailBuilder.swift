//
//  ChangeEmailBuilder.swift
//  Gula
//
//  Created by Jesu Castellano on 5/11/24.
//

import Foundation

class ChangeEmailBuilder {
    func build() -> ChangeEmailView {
        let network = Config.shared.network
        let errorHandler = ErrorHandlerManager()
        let datasource = UserRemoteDatasource(network: network)
        let repository = UserRepository(dataSource: datasource, errorHandler: errorHandler)
        let userUseCase = UserUseCase(repository: repository)
        let validationUseCase = ValidationUseCase()
        let viewModel = ChangeEmailViewModel(validationUseCase: validationUseCase, userUseCase: userUseCase)
        return ChangeEmailView(viewModel: viewModel)
    }
}
