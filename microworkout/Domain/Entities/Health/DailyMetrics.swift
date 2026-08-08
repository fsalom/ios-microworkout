import Foundation

/// De dónde salió el dato. Importa porque cambia cuánto fiarse: lo de Salud lo ha
/// escrito una báscula, un reloj o el propio usuario en otra app; lo manual, aquí.
enum MeasurementSource: String, Codable, Equatable {
    case health
    case manual
}

/// Lo medido de UN día: composición corporal, actividad y recuperación.
///
/// Empezó siendo solo el peso y se quedó corto en cuanto el coach tuvo que
/// razonar sobre la evolución de alguien: los pasos y la frecuencia en reposo
/// llegaban en la foto de hoy y se tiraban.
///
/// `date` se normaliza al principio del día: la identidad de un registro es el
/// día, no el instante. Si te pesas tres veces un martes, el peso del martes es
/// uno.
struct DailyMetrics: Identifiable, Equatable, Codable {
    let date: Date

    // Composición corporal
    var weightKg: Double?
    var bodyFatPercentage: Double?

    // Actividad
    var steps: Int?
    var activeKcal: Double?
    var exerciseMinutes: Double?
    var standingMinutes: Double?

    // Recuperación
    var restingHeartRate: Double?

    var source: MeasurementSource

    var id: Date { date }

    /// `true` si el día no tiene ni un dato. Sirve para no mandar al servidor
    /// filas vacías: un día sin nada medido no es información.
    var isEmpty: Bool {
        weightKg == nil && bodyFatPercentage == nil && steps == nil
            && activeKcal == nil && exerciseMinutes == nil
            && standingMinutes == nil && restingHeartRate == nil
    }

    init(
        date: Date,
        weightKg: Double? = nil,
        bodyFatPercentage: Double? = nil,
        steps: Int? = nil,
        activeKcal: Double? = nil,
        exerciseMinutes: Double? = nil,
        standingMinutes: Double? = nil,
        restingHeartRate: Double? = nil,
        source: MeasurementSource = .manual
    ) {
        self.date = Calendar.current.startOfDay(for: date)
        self.weightKg = weightKg
        self.bodyFatPercentage = bodyFatPercentage
        self.steps = steps
        self.activeKcal = activeKcal
        self.exerciseMinutes = exerciseMinutes
        self.standingMinutes = standingMinutes
        self.restingHeartRate = restingHeartRate
        self.source = source
    }

    /// Combina dos registros del mismo día quedándose con lo que tenga cada uno.
    ///
    /// Es lo que evita que la actividad del reloj borre el peso de la báscula: se
    /// prefiere `other` campo a campo, pero solo donde `other` tiene dato.
    func merged(with other: DailyMetrics) -> DailyMetrics {
        DailyMetrics(
            date: date,
            weightKg: other.weightKg ?? weightKg,
            bodyFatPercentage: other.bodyFatPercentage ?? bodyFatPercentage,
            steps: other.steps ?? steps,
            activeKcal: other.activeKcal ?? activeKcal,
            exerciseMinutes: other.exerciseMinutes ?? exerciseMinutes,
            standingMinutes: other.standingMinutes ?? standingMinutes,
            restingHeartRate: other.restingHeartRate ?? restingHeartRate,
            source: other.source
        )
    }
}

/// Resumen de la serie de peso: cuánto ha cambiado, en cuánto tiempo y a qué ritmo.
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
    static func from(_ measurements: [DailyMetrics]) -> WeightTrend? {
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

// `rounded(toPlaces:)` vive en Shared/Extensions: es un helper genérico de
// `Double`, no parte del modelo de una medida diaria.
