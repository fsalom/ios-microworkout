//
//  ValidationUseCase.swift
//  Gula
//
//  Created by Jorge Planells Zamora on 8/7/24.
//

import Foundation

class ValidationUseCase: ValidationUseCaseProtocol {
    func validate(email: String) -> Bool {
        let emailRegex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9-]+(\\.[A-Za-z0-9-]+)*(\\.[A-Za-z]{2,})$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }

    func validate(password: String) -> Bool {
        let passwordRegex = "^(?=.*[A-Z])(?=.*[a-z])(?=.*[^a-zA-Z0-9])(?=.*[0-9]).{8,15}$"
        let passwordPredicate = NSPredicate(format: "SELF MATCHES %@", passwordRegex)
        return passwordPredicate.evaluate(with: password)
    }

    func validate(phone: String) -> Bool {
        let phoneRegex = "^[679]\\d{8}$"
        let phonePredicate = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
        return phonePredicate.evaluate(with: phone)
    }

    func validate(postalCode: String) -> Bool {
        let postalCodeRegex = "^[0-5][0-9]{4}$"
        let postalCodePredicate = NSPredicate(format: "SELF MATCHES %@", postalCodeRegex)
        return postalCodePredicate.evaluate(with: postalCode)
    }
}
