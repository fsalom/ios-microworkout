//
//  WorkoutSelectionProtocols.swift
//  microworkout
//
//  Created by Fernando Salom Carratala on 21/11/23.
//

import Foundation

protocol WorkoutSelectionViewModelProtocol: ObservableObject  {
    var workouts: [WorkoutPlan] { get set }
    func load()
}
