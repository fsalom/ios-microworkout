//
//  ErrorHandlerProtocol.swift
//  Gula
//
//  Created by Jorge Planells Zamora on 11/7/24.
//

import Foundation

protocol ErrorHandlerProtocol {
    func handle(_ error: Error) -> Error
}
