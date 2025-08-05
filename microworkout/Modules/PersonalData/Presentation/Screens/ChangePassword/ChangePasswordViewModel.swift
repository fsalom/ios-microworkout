//
//  Gula
//
//  ChangePasswordViewModel.swift
//
//  Created by Rudo Apps on 7/5/25
//

import Foundation
import SwiftUI

class ChangePasswordViewModel: ObservableObject {
    // MARK: UIState
    struct UIState {
        var hasChangePasswordSucceeded = false
        var arePasswordsEqual = true
        var isValidPassword = true
        var passwordErrorMessage = "common_wrongPasswordFormat"
        var areAllFieldsOk = false
        var error: UserError?
    }

    // MARK: Properties
    @Binding var needToShowToast: Bool
    @Published var uiState = UIState()
    @Published var password: String = "" {
        didSet {
            checkPassword()
        }
    }
    @Published var repeatPassword: String = "" {
        didSet {
            checkIfPasswordsMatch()
        }
    }
    private let validationUseCase: ValidationUseCaseProtocol
    private let userUseCase: UserUseCaseProtocol

    // MARK: Init
    init(validationUseCase: ValidationUseCaseProtocol,
         userUseCase: UserUseCaseProtocol,
         needToShowToast: Binding<Bool>) {
        self.validationUseCase = validationUseCase
        self.userUseCase = userUseCase
        self._needToShowToast = needToShowToast
    }

    // MARK: Functions
    @MainActor
    func changePassword() {
        Task {
            do {
                try await userUseCase.updatePassword(with: password)
                uiState.hasChangePasswordSucceeded = true
                needToShowToast = true
            } catch {
                if let error = error as? UserError {
                    uiState.error = error
                }
            }
        }
    }

    func checkIfReadyToChangePassword() {
        uiState.areAllFieldsOk = uiState.isValidPassword && !password.isEmpty && !repeatPassword.isEmpty && uiState.arePasswordsEqual
    }

    private func checkPassword() {
        uiState.isValidPassword = validationUseCase.validate(password: password)
    }

    private func checkIfPasswordsMatch() {
        uiState.arePasswordsEqual = password == repeatPassword
    }
}
