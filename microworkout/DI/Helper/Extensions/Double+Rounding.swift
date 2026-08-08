//
//  Double+Rounding.swift
//  microworkout
//

import Foundation

extension Double {
    /// Redondea a `places` decimales.
    ///
    /// Vivía dentro de `DailyMetrics.swift`, que es un archivo de entidad: una
    /// extensión `internal` de `Double` no es parte del modelo de una medida diaria
    /// y desde allí la exportaba a todo el target sin que se viera venir.
    func rounded(toPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}
