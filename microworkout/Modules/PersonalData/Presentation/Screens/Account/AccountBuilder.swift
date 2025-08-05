//
//  AccountBuilder.swift
//  Gula
//
//  Created by Maria on 7/11/24.
//

import Foundation

class AccountBuilder {
    func build() -> AccountView {
        let errorHandler = ErrorHandlerManager()
        let network = Config.shared.network

        let userDataSource = UserRemoteDatasource(network: network)
        let userRepository = UserRepository(dataSource: userDataSource, errorHandler: errorHandler)
        let userUseCase = UserUseCase(repository: userRepository)
        let viewModel = AccountViewModel(userUseCase: userUseCase)
        let view = AccountView(viewModel: viewModel)
        return view
    }
}
