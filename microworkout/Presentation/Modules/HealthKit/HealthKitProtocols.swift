//
//  HealthKitProtocols.swift
//  microworkout
//
//  Created by Fernando Salom Carratala on 5/8/23.
//

import Foundation

protocol HealthKitViewModelProtocol: ObservableObject  {
    var workouts: [WorkoutPlan] { get set }
    var beats: [Beat] { get set }
    func load() async
}
