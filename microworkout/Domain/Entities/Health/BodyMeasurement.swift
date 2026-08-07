import Foundation

/// De dónde salió la medida. Importa porque cambia cuánto fiarse: lo de Salud lo
/// ha escrito una báscula (o el usuario en otra app) y lo manual se ha tecleado
/// aquí — aunque lo manual también acaba en Salud, para no tener dos verdades.
enum MeasurementSource: String, Codable, Equatable {
    case health
    case manual
}

/// Una medida corporal de UN día.
///
/// El perfil guarda el peso actual, que sirve para calcular calorías. Esto es la
/// serie, que es lo único que permite hablar de progresión: "has bajado 1,8 kg en
/// seis semanas" en vez de "pesas 78".
///
/// `date` se normaliza al principio del día: la identidad de una medida es el día,
/// no el instante. Si te pesas tres veces un martes, el peso del martes es uno.
struct BodyMeasurement: Identifiable, Equatable, Codable {
    let date: Date
    var weightKg: Double?
    var bodyFatPercentage: Double?
    var source: MeasurementSource

    var id: Date { date }

    init(
        date: Date,
        weightKg: Double? = nil,
        bodyFatPercentage: Double? = nil,
        source: MeasurementSource = .manual
    ) {
        self.date = Calendar.current.startOfDay(for: date)
        self.weightKg = weightKg
        self.bodyFatPercentage = bodyFatPercentage
        self.source = source
    }
}

/// Resumen de la serie: cuánto ha cambiado el peso, en cuánto tiempo y a qué ritmo.
struct WeightTrend: Equatable {
    let from: Double
    let to: Double
    let deltaKg: Double
    let days: Int

    /// `nil` con menos de una semana: dividir 0,4 kg entre dos días y decir
    /// "1,4 kg/semana" es inventarse una velocidad que no se ha medido.
    var kgPerWeek: Double? {
        guard days >= 7 else { return nil }
        return (deltaKg / (Double(days) / 7)).rounded(toPlaces: 2)
    }

    /// Tendencia entre la primera y la última medida con peso.
    /// `nil` con menos de dos: una sola medida no es una tendencia.
    static func from(_ measurements: [BodyMeasurement]) -> WeightTrend? {
        let withWeight = measurements
            .filter { $0.weightKg != nil }
            .sorted { $0.date < $1.date }
        guard let first = withWeight.first, let last = withWeight.last,
              withWeight.count >= 2,
              let from = first.weightKg, let to = last.weightKg else { return nil }
        return WeightTrend(
            from: from,
            to: to,
            deltaKg: (to - from).rounded(toPlaces: 2),
            days: Calendar.current.dateComponents([.day], from: first.date, to: last.date).day ?? 0
        )
    }
}

extension Double {
    func rounded(toPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}
