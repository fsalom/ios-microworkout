//
//  CurrentSessionViewModel.swift
//  microworkout
//
//  Created by Fernando Salom Carratala on 19/7/25.
//


import SwiftUI
import Combine

class ProfileViewModel: ObservableObject {
    private var exerciseUseCase: ExerciseUseCaseProtocol
    private var loggedExerciseUseCase: LoggedExerciseUseCaseProtocol

    init(exerciseUseCase: ExerciseUseCaseProtocol, loggedExerciseUseCase: LoggedExerciseUseCaseProtocol) {
        self.exerciseUseCase = exerciseUseCase
        self.loggedExerciseUseCase = loggedExerciseUseCase
    }

    
}
