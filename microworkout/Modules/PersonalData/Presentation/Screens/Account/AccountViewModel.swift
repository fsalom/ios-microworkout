//
//  AccountViewModel.swift
//  Gula
//
//  Created by Maria on 7/11/24.
//

import Foundation
import SwiftUI

class AccountViewModel: ObservableObject {
    struct UIState {
        var error: UserError?
        var didFindErrorWhenDeletingAccount = false
        var isDeleteAccountSuccessful = false
    }

    // MARK: - Properties
    private let userUseCase: UserUseCaseProtocol
    @Published var userName: String = ""
    @Published var uiState = UIState()

    // MARK: - Init
    init(userUseCase: UserUseCaseProtocol) {
        self.userUseCase = userUseCase
    }

    // MARK: - Functions
    @MainActor
    func deleteAccount() {
        Task {
            do {
                try await userUseCase.deleteAccount()
                uiState.isDeleteAccountSuccessful = true
                logout()
            } catch {
                uiState.didFindErrorWhenDeletingAccount = true
            }
        }
    }

    @MainActor
    func getUser() {
        Task {
            do {
                let user = try await userUseCase.getUser()
                userName = user.fullname
            } catch {
                if let error = error as? UserError {
                    uiState.error = error
                }
            }
        }
    }

    @MainActor
    func logout() {
        Task {
            do {
                try await userUseCase.logout()
            } catch {
                if let error = error as? UserError {
                    uiState.error = error
                }
            }
        }
    }
}

enum ToastType {
    case email
    case password
    case deleteAccount

    var message: LocalizedStringKey {
        switch self {
        case .email:
            "account_emailProperlyUpdated"
        case .password:
            "account_passwordProperlyUpdated"
        case .deleteAccount:
            "account_deleteAccountSuccess"
        }
    }
}
