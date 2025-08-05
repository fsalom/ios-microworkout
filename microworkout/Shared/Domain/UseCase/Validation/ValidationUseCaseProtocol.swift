//
//  ValidationUseCaseProtocol.swift
//  Gula
//
//  Created by Jorge Planells Zamora on 8/7/24.
//

import Foundation

protocol ValidationUseCaseProtocol {
    func validate(email: String) -> Bool
    func validate(password: String) -> Bool
    func validate(phone: String) -> Bool
    func validate(postalCode: String) -> Bool
}
