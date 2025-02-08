//
//  WorkoutSelectionBuilder.swift
//  microworkout
//
//  Created by Fernando Salom Carratala on 21/11/23.
//

import Foundation

class WorkoutSelectionBuilder {
    func build() -> WorkoutSelectionView {
        let useCase = WorkoutUseCase()

        let viewModel = WorkoutSelectionViewModel(useCase: useCase)
        let view = WorkoutSelectionView(viewModel: viewModel)
        return view
    }
}
