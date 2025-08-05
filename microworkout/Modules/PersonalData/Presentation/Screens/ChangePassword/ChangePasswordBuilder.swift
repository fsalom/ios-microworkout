//
//  Gula
//
//  ChangePasswordBuilder.swift
//
//  Created by Rudo Apps on 7/5/25
//

import Foundation
import SwiftUI

class ChangePasswordBuilder {
    func build(needToShowToast: Binding<Bool>) -> ChangePasswordView {
        let network = Config.shared.network
        let errorHandler = ErrorHandlerManager()
        let validationUseCase = ValidationUseCase()

        let userRemoteDatasource = UserRemoteDatasource(network: network)
        let repository = UserRepository(dataSource: userRemoteDatasource, errorHandler: errorHandler)
        let userUseCase = UserUseCase(repository: repository)

        let viewModel = ChangePasswordViewModel(validationUseCase: validationUseCase,
                                                userUseCase: userUseCase,
                                                needToShowToast: needToShowToast)
        let view = ChangePasswordView(viewModel: viewModel)
        return view
    }
}
