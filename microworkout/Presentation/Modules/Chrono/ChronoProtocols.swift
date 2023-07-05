//
//  TimerProtocols.swift
//  microworkout
//
//  Created by Fernando Salom Carratala on 9/6/23.
//

import Foundation

protocol ChronoViewModelProtocol: ObservableObject  {    
    var seconds: Double { get set }
    func load()
}
