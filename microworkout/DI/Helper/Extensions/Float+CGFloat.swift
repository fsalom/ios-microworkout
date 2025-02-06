//
//  Float+CGFloat.swift
//  microworkout
//
//  Created by Fernando Salom Carratala on 11/7/23.
//

import Foundation

extension Float {
    var formatted: String {
        return self.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", self) : String(self)
    }
}

extension CGFloat {
    var formatted: String {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.minimumFractionDigits = 2
        numberFormatter.maximumFractionDigits = 2

        return numberFormatter.string(from: self as NSNumber) ?? "-"
    }
}
