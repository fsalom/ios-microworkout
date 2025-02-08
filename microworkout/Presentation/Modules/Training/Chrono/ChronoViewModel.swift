//
//  TimerViewModel.swift
//  microworkout
//
//  Created by Fernando Salom Carratala on 9/6/23.
//

import Foundation

class ChronoViewModel: ObservableObject, ChronoViewModelProtocol {
    var seconds: Double
    var useCase: WorkoutUseCaseProtocol!
    var progression: Float

    init(useCase: WorkoutUseCaseProtocol, seconds: Double) {
        self.useCase = useCase
        self.seconds = seconds
        self.progression = Float(seconds / 100)
    }
}
