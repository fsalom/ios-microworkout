//
//  DetailWorkoutViewModel.swift
//  microworkout
//
//  Created by Fernando Salom Carratala on 6/7/23.
//

import Foundation
import SwiftUI

class DetailWorkoutViewModel: ObservableObject {

    var useCase: WorkoutUseCaseProtocol!

    init(useCase: WorkoutUseCaseProtocol) {
        self.useCase = useCase
    }

    func load() {
        Task {
            
        }
    }
}
