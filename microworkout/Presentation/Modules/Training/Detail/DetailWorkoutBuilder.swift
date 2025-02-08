//
//  DetailWorkoutBuilder.swift
//  microworkout
//
//  Created by Fernando Salom Carratala on 6/7/23.
//

import Foundation
import SwiftUI

class DetailWorkoutBuilder {
    func build(with plan: Binding<WorkoutPlan>) -> DetailWorkoutView {
        let usecase = WorkoutUseCase()
        let viewModel = DetailWorkoutViewModel(useCase: usecase)
        let view = DetailWorkoutView(plan: plan, viewModel: viewModel)
        return view
    }
}
