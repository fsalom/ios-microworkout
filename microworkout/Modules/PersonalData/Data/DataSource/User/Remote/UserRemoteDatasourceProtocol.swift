//
//  UserRemoteDatasourceProtocol.swift
//  Gula
//
//  Created by Axel Pérez Gaspar on 22/8/24.
//

import Foundation

protocol UserRemoteDatasourceProtocol {
    func getUser() async throws -> UserDTO
    func updateUser(name: String, phone: String) async throws -> UserDTO
    func deleteAccount() async throws
    func logout() async throws
    func validatePassword(_ password: String) async throws
    func updatePassword(with password: String) async throws
    func change(this email: String) async throws
}
