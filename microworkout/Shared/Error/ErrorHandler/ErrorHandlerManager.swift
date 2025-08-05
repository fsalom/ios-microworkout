//
//  ErrorHandlerManager.swift
//  Gula
//
//  Created by Jorge Planells Zamora on 11/7/24.
//

import Foundation
import TripleA

class ErrorHandlerManager: ErrorHandlerProtocol {
    func handle(_ error: Error) -> Error {
        if let error = error as? NetworkError {
            switch error {
            case .failure(let statusCode , let data, _):
                return parse(data: data, statusCode: statusCode)
            case .errorData(let data):
                return parse(data: data)
            default:
                return AppError.generalError
            }
        } else if let authError = error as? TripleA.AuthError {
            switch authError {
            case .notAuthorized:
                return AppError.badCredentials("common_wrongCredentialsMessage")
            case .errorData(let data):
                return parse(data: data)
            case .noInternet:
                return AppError.noInternet
            default:
                return AppError.generalError
            }
        } else if (error as NSError).domain == NSURLErrorDomain {
            return AppError.noInternet
        }
        return AppError.generalError
    }

    private func parse(data: Data?, statusCode: Int? = nil) -> AppError {
        guard let data else { return AppError.generalError }
        let errors = try? JSONDecoder().decode([ErrorDTO].self, from: data)
        guard let error = errors?.first else { return AppError.generalError }

        if let errors, let field = error.field {
            if errors.count > 1 {
                let fields = errors.compactMap { $0.field }
                let messages = errors.map { $0.message }
                return AppError.inputsError(fields, messages)
            } else {
                return AppError.inputError(field, error.message)
            }
        }

        if error.type == "invalid_credentials" {
            return AppError.badCredentials(error.message)
        } else {
            return AppError.customError(error.message, statusCode)
        }
    }
}
