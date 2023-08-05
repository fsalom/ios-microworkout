//
//  HealthKitBuilder.swift
//  microworkout
//
//  Created by Fernando Salom Carratala on 5/8/23.
//

import Foundation

class HealthKitBuilder {
    func build() -> HealthKitView {
        let useCase = WorkoutUseCase()

        let viewModel = HealthKitViewModel(useCase: useCase)
        let view = HealthKitView(viewModel: viewModel)
        return view
    }
}
