//
//  Beat.swift
//  microworkout
//
//  Created by Fernando Salom Carratala on 9/8/23.
//

import Foundation


struct Beat: Identifiable {
    var id: String = UUID().uuidString
    var value: Double
    var start: Date
    var end: Date
}
