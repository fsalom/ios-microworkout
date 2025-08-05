//
//  UserRemoteDatasource.swift
//  Gula
//
//  Created by Axel Pérez Gaspar on 22/8/24.
//

import Foundation
import TripleA

final class UserRemoteDatasource: UserRemoteDatasourceProtocol {
    private let network: Network

    init(network: Network) {
        self.network = network
    }

    func getUser() async throws -> UserDTO {
        let endpoint = Endpoint(path: "api/users/me", httpMethod: .get)
        return try await network.loadAuthorized(this: endpoint, of: UserDTO.self)
    }

    func updateUser(name: String, phone: String) async throws -> UserDTO {
        let parameters = ["fullname": name,
                          "phone": phone]
        let endpoint = Endpoint(path: "api/users/update", httpMethod: .put, parameters: parameters)
        return try await network.loadAuthorized(this: endpoint, of: UserDTO.self)
    }

    func deleteAccount() async throws {
        let endpoint = Endpoint(path: "api/users/delete", httpMethod: .delete)
        _ = try await network.loadAuthorized(this: endpoint)
    }

    func logout() async throws {
        let endpoint = Endpoint(path: "api/users/logout", httpMethod: .post)
        _ = try await self.network.loadAuthorized(this: endpoint)
        try await network.authenticator?.logout()
    }

    func validatePassword(_ password: String) async throws {
        let parameters = ["password": password]
        let endpoint = Endpoint(path: "api/users/validate-password", httpMethod: .post, parameters: parameters)
        _ = try await network.loadAuthorized(this: endpoint)
    }

    func updatePassword(with password: String) async throws {
        let parameters = ["password": password]
        let endpoint = Endpoint(path: "api/users/change-old-password", httpMethod: .put, parameters: parameters)
        _ = try await network.loadAuthorized(this: endpoint)
    }

    func change(this email: String) async throws {
        let parameters = ["email": email]
        let endpoit = Endpoint(path: "api/users/change-email", httpMethod: .put, parameters: parameters)
        _ = try await network.loadAuthorized(this: endpoit)
    }
}
