//
//  HomeBuilder.swift
//  microworkout
//
//  Created by Fernando Salom Carratala on 8/6/23.
//

import Foundation

class HomeBuilder {
    func build() -> HomeView {
        let useCase = WorkoutUseCase()

        let viewModel = HomeViewModel(useCase: useCase)
        let view = HomeView(viewModel: viewModel)
        return view
    }
}
