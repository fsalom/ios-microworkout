import Foundation

/// Respuesta de `/v1/profile/measurements`.
///
/// `date` viaja como día suelto (`2026-08-01`), no como instante: la medida es de
/// un día, no de un momento. Por eso se formatea a mano y no con el decodificador
/// de fechas ISO del resto de DTOs, que espera hora y zona y fallaría.
struct BodyMeasurementApiDTO: Decodable {
    let date: Date
    let weightKg: Double?
    let bodyFatPercentage: Double?
    let source: String

    enum CodingKeys: String, CodingKey {
        case date
        case weightKg = "weight_kg"
        case bodyFatPercentage = "body_fat_percentage"
        case source
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let raw = try container.decode(String.self, forKey: .date)
        guard let parsed = BodyMetricsDateFormat.day.date(from: raw) else {
            throw DecodingError.dataCorrupted(
                .init(codingPath: [CodingKeys.date], debugDescription: "Fecha no válida: \(raw)")
            )
        }
        date = parsed
        weightKg = try container.decodeIfPresent(Double.self, forKey: .weightKg)
        bodyFatPercentage = try container.decodeIfPresent(Double.self, forKey: .bodyFatPercentage)
        source = try container.decode(String.self, forKey: .source)
    }

    func toDomain() -> BodyMeasurement {
        BodyMeasurement(
            date: date,
            weightKg: weightKg,
            bodyFatPercentage: bodyFatPercentage,
            // Una fuente que no conocemos se trata como manual: es lo que el
            // usuario puede corregir, así que es el lado seguro.
            source: MeasurementSource(rawValue: source) ?? .manual
        )
    }
}

struct MeasurementTrendApiDTO: Decodable {
    let deltaKg: Double
    let days: Int
    let kgPerWeek: Double?
    let fromKg: Double
    let toKg: Double

    enum CodingKeys: String, CodingKey {
        case deltaKg = "delta_kg"
        case days
        case kgPerWeek = "kg_per_week"
        case fromKg = "from_kg"
        case toKg = "to_kg"
    }
}

struct MeasurementListApiDTO: Decodable {
    let measurements: [BodyMeasurementApiDTO]
    let trend: MeasurementTrendApiDTO?
}

enum BodyMetricsDateFormat {
    /// Día local, sin hora. `en_US_POSIX` y calendario gregoriano porque el
    /// formato es del protocolo, no del idioma del móvil: con otro calendario
    /// (budista, japonés) el año saldría distinto y el backend lo rechazaría.
    static let day: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}
