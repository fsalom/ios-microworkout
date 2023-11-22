//
//  HealthRepository.swift
//  microworkout
//
//  Created by Fernando Salom Carratala on 22/11/23.
//

import Foundation

class HealthRepository: HealthRepositoryProtocol {
    private var dataSource: HealthKitDataSourceProtocol!

    init(dataSource: HealthKitDataSourceProtocol){
        self.dataSource = dataSource
    }
}
