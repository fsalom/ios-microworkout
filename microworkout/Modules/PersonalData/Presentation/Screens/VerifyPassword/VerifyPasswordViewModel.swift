//
//  VerifyPasswordViewModel.swift
//  Gula
//
//  Created by Adrian Prieto Villena on 4/11/24.
//

import Foundation

class VerifyPasswordViewModel: ObservableObject {
    struct UIState {
        var error: UserError?
        var isValidPassword = true
        var isPasswordVerified = false
        var hasStartTyping = false
    }
    // MARK: - Properties
    @Published var uiState = UIState()
    @Published var password: String = ""
    private let userUseCase: UserUseCaseProtocol

    init(userUseCase: UserUseCaseProtocol) {
        self.userUseCase = userUseCase
    }

    @MainActor
    func verifyPassword() {
        Task {
            do {
                try await userUseCase.validatePassword(password)
                uiState.isPasswordVerified = true
                uiState.isValidPassword = true
            } catch {
                uiState.isPasswordVerified = false
                if let error = error as? UserError {
                    uiState.error = error
                }
            }
        }
    }
}
