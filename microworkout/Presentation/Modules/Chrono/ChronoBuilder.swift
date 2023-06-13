//
//  TimerBuilder.swift
//  microworkout
//
//  Created by Fernando Salom Carratala on 9/6/23.
//

import Foundation

class ChronoBuilder {
    func build() -> ChronoView<ChronoViewModel> {
        let useCase = WorkoutUseCase()

        let viewModel = ChronoViewModel(useCase: useCase, seconds: 12)
        let view = ChronoView(viewModel: viewModel)
        return view
    }
}
