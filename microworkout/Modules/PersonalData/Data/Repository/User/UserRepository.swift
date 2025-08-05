//
//  UserRepository.swift
//  Gula
//
//  Created by Axel Pérez Gaspar on 22/8/24.
//

import Foundation

final class UserRepository: UserRepositoryProtocol {
    // MARK: - Properties
    private let dataSource: UserRemoteDatasourceProtocol
    private let errorHandler: ErrorHandlerProtocol

    // MARK: - Init
    init(dataSource: UserRemoteDatasourceProtocol, errorHandler: ErrorHandlerProtocol) {
        self.dataSource = dataSource
        self.errorHandler = errorHandler
    }

    func getUser() async throws -> User {
        do {
            let userDTO = try await dataSource.getUser()
            return userDTO.toDomain()
        } catch {
            throw errorHandler.handle(error)
        }
    }

    func updateUser(name: String, phone: String) async throws -> User {
        do {
            let userDTO = try await dataSource.updateUser(name: name, phone: phone)
            return userDTO.toDomain()
        } catch {
            throw errorHandler.handle(error)
        }
    }

    func deleteAccount() async throws {
        do {
            try await dataSource.deleteAccount()
        } catch {
            throw errorHandler.handle(error)
        }
    }

    func logout() async throws {
        do {
            try await dataSource.logout()
        } catch {
            throw errorHandler.handle(error)
        }
    }

    func validatePassword(_ password: String) async throws {
        do {
            try await dataSource.validatePassword(password)
        } catch {
            throw errorHandler.handle(error)
        }
    }

    func updatePassword(with password: String) async throws {
        do {
            try await dataSource.updatePassword(with: password)
        } catch {
            throw errorHandler.handle(error)
        }
    }

    func change(this email: String) async throws {
        do {
            try await dataSource.change(this: email)
        } catch {
            throw errorHandler.handle(error)
        }
    }
}

fileprivate extension UserDTO {
    func toDomain() -> User {
        User(id: self.id,
             fullname: self.fullname,
             phone: self.phone,
             email: self.email)
    }
}
