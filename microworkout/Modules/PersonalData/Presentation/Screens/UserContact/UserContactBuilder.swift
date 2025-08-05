//
//  ContactBuilder.swift
//  Gula
//
//  Created by Jorge on 29/8/24.
//

import Foundation
import TripleA

class UserContactBuilder {
    func build() -> UserContactView {
        let network = Config.shared.network
        let errorHandler = ErrorHandlerManager()

        let userDataSource = UserRemoteDatasource(network: network)
        let userRepository = UserRepository(dataSource: userDataSource, errorHandler: errorHandler)
        let userUseCase = UserUseCase(repository: userRepository)

        let validationUseCase = ValidationUseCase()
        let viewModel = UserContactViewModel(validationUseCase: validationUseCase, userUseCase: userUseCase)
        let view = UserContactView(viewModel: viewModel)
        return view
    }
}
