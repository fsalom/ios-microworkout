//
//  HomeProtocols.swift
//  microworkout
//
//  Created by Fernando Salom Carratala on 8/6/23.
//

import Foundation

protocol HomeViewModelProtocol: ObservableObject  {
    var workouts: [WorkoutPlan] { get set }
    func load()
}
