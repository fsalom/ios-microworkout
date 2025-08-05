//
//  ChangeEmailViewModel.swift
//  Gula
//
//  Created by Jesu Castellano on 5/11/24.
//

import Foundation

class ChangeEmailViewModel: ObservableObject {

    struct UIState {
        var isValidEmail = true
        var sendButtonState: ButtonState = .normal
        var error: UserError?
        var hasEmailBeenSent = false
        var emailErrorMessage = "auth_wrongEmailFormat"
    }

    @Published var email: String = "" {
        didSet {
            check(this: email)
        }
    }
    private let validationUseCase: ValidationUseCaseProtocol
    private let userUseCase: UserUseCaseProtocol
    @Published var uiState = UIState()

    // MARK: - Init
    init(validationUseCase: ValidationUseCaseProtocol, userUseCase: UserUseCaseProtocol) {
        self.validationUseCase = validationUseCase
        self.userUseCase = userUseCase
    }

    private func check(this email: String) {
        uiState.isValidEmail = validationUseCase.validate(email: email) && !email.isEmpty
    }

    @MainActor
    func changeEmail() {
        Task {
            do {
                try await userUseCase.change(this: email)
                uiState.hasEmailBeenSent = true
            } catch {
                if let error = error as? UserError {
                    uiState.error = error
                }
            }
        }
    }
}
