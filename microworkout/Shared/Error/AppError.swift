//
//  GenericError.swift
//  Gula
//
//  Created by Jorge Planells Zamora on 12/7/24.
//

import Foundation

protocol DetailErrorProtocol: Error, Equatable {
    var title: String { get }
    var message: String { get }
}

enum AppError: DetailErrorProtocol {
    case generalError
    case noInternet
    case badCredentials(String)
    case customError(String, Int?)
    case inputError(String,String)
    case inputsError([String],[String])

    var title: String {
        switch self {
        case .inputError(let field, _):
            return field
        case .noInternet:
            return "common_connectionError"
        default:
            return "common_tryAgain"
        }
    }

    var message: String {
        switch self {
        case .generalError:
            return "common_generalError"
        case .customError(let message, _):
            return message
        case .noInternet:
            return "common_noInternetMessage"
        case .badCredentials:
            return "badCredentials"
        case .inputError(_, let message):
            return message
        case .inputsError:
            return ""
        }
    }
}
