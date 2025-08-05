//
//  UserUseCase.swift
//  Gula
//
//  Created by Axel Pérez Gaspar on 22/8/24.
//

import Foundation

enum UserError: DetailErrorProtocol {
    var title: String {
        switch self {
        case .appError(let title,_):
            title
        default:
            "tryAgain"
        }
    }

    var message: String {
        switch self {
        case .appError(_, let message):
            message
        case .inputFullnameError(let message):
            message
        case .inputPhoneError(let message):
            message
        case .inputPasswordError(let message):
            message
        case .inputEmailError(let message):
            message
        default:
            "generalError"
        }
    }

    case appError(String, String)
    case inputsError([String], [String])
    case inputFullnameError(String)
    case inputPhoneError(String)
    case inputPasswordError(String)
    case inputEmailError(String)
    case generalError
}

final class UserUseCase: UserUseCaseProtocol {
    // MARK: - Properties
    var repository: UserRepositoryProtocol

    // MARK: - Init
    init(repository: UserRepositoryProtocol) {
        self.repository = repository
    }

    // MARK: - Functions
    func getUser() async throws -> User {
        do {
            return try await repository.getUser()
        } catch let error as AppError {
            throw handle(error)
        }
    }

    func updateUser(name: String, phone: String) async throws -> User {
        do {
            return try await repository.updateUser(name: name, phone: phone)
        } catch let error as AppError {
            throw handle(error)
        }
    }

    func deleteAccount() async throws {
        do {
            try await repository.deleteAccount()
        } catch let error as AppError {
            throw handle(error)
        }
    }

    func logout() async throws {
        do {
            try await repository.logout()
        } catch let error as AppError {
            throw handle(error)
        }
    }

    func validatePassword(_ password: String) async throws {
        do {
            try await repository.validatePassword(password)
        } catch let error as AppError {
            throw handle(error)
        }
    }

    func updatePassword(with password: String) async throws {
        do {
            try await repository.updatePassword(with: password)
        } catch let error as AppError {
            throw handle(error)
        }
    }

    func change(this email: String) async throws {
        do {
            try await repository.change(this: email)
        } catch let error as AppError {
            throw handle(error)
        }
    }
}

private extension UserUseCase {
    func handle(_ error: AppError) -> UserError {
        switch error {
        case .customError:
            return UserError.appError(error.title, error.message)
        case .inputError(let field, let message):
            switch field {
            case "email":
                return .inputEmailError(message)
            case "password":
                return .inputPasswordError(message)
            default:
                return .appError("tryAgain", "generalError")
            }
        case .inputsError(let fields, let messages):
            return .inputsError(fields, messages)
        default:
            return .generalError
        }
    }
}
