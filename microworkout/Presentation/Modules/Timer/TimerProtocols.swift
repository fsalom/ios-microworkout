//
//  TimerProtocols.swift
//  microworkout
//
//  Created by Fernando Salom Carratala on 9/6/23.
//

import Foundation

protocol TimerViewModelProtocol: ObservableObject  {
    var workout: Workout { get set }
    func load()
}
