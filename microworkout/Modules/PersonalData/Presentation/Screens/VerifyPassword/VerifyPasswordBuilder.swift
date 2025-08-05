//
//  VerifyPasswordBuilder.swift
//  Gula
//
//  Created by Adrian Prieto Villena on 4/11/24.
//

import Foundation
import SwiftUI

class VerifyPasswordBuilder {
    func build(isShowingVerifyPasswordSheet: Binding<Bool>,
               navigateToNewPassword: Binding<Bool>) -> VerifyPasswordView {
        let errorHandler = ErrorHandlerManager()
        let network = Config.shared.network

        let dataSource = UserRemoteDatasource(network: network)
        let repository = UserRepository(dataSource: dataSource, errorHandler: errorHandler)
        let userUseCase = UserUseCase(repository: repository)

        let viewModel = VerifyPasswordViewModel(userUseCase: userUseCase)
        let view = VerifyPasswordView(viewModel: viewModel,
                                      isShowingVerifyPasswordSheet: isShowingVerifyPasswordSheet,
                                      navigateToNewPassword: navigateToNewPassword)
        return view
    }
}
