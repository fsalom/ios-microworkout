//
//  HealthUseCase.swift
//  microworkout
//
//  Created by Fernando Salom Carratala on 22/11/23.
//

import Foundation

class HealthUseCase {
    var repository: HealthRepositoryProtocol!

    init(repository: HealthRepositoryProtocol) {
        self.repository = repository
    }
}
