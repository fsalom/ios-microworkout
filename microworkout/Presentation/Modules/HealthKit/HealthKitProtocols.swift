//
//  HealthKitProtocols.swift
//  microworkout
//
//  Created by Fernando Salom Carratala on 5/8/23.
//

import Foundation

protocol HealthKitViewModelProtocol: ObservableObject  {
    var workouts: [WorkoutPlan] { get set }
    func load()
}
