import Foundation

protocol BodyMetricsLocalDataSourceProtocol {
    func getAll() -> [BodyMeasurementDTO]
    func save(_ measurement: BodyMeasurementDTO)
    func delete(date: Date)
}

/// Copia en el dispositivo de las medidas.
///
/// Salud es la fuente, pero puede no estar: si el usuario no da permiso, o el
/// dispositivo no tiene HealthKit, lo que anote tiene que quedarse en algún sitio.
/// Además es lo que la sincronización sube a la cuenta cuando el servidor falla.
final class BodyMetricsLocalDataSource: BodyMetricsLocalDataSourceProtocol {
    private let storage: UserDefaultsManagerProtocol
    private let key = "bodyMetrics.measurements"

    init(storage: UserDefaultsManagerProtocol) {
        self.storage = storage
    }

    func getAll() -> [BodyMeasurementDTO] {
        storage.get(forKey: key) ?? []
    }

    func save(_ measurement: BodyMeasurementDTO) {
        var all: [BodyMeasurementDTO] = storage.get(forKey: key) ?? []
        // Una por día: la clave es el día, igual que en el servidor y en Salud.
        all.removeAll { Calendar.current.isDate($0.date, inSameDayAs: measurement.date) }
        all.append(measurement)
        storage.save(all, forKey: key)
    }

    func delete(date: Date) {
        var all: [BodyMeasurementDTO] = storage.get(forKey: key) ?? []
        all.removeAll { Calendar.current.isDate($0.date, inSameDayAs: date) }
        storage.save(all, forKey: key)
    }
}

struct BodyMeasurementDTO: Codable {
    var date: Date
    var weightKg: Double?
    var bodyFatPercentage: Double?
    var source: String

    func toDomain() -> BodyMeasurement {
        BodyMeasurement(
            date: date,
            weightKg: weightKg,
            bodyFatPercentage: bodyFatPercentage,
            source: MeasurementSource(rawValue: source) ?? .manual
        )
    }
}

extension BodyMeasurement {
    func toDTO() -> BodyMeasurementDTO {
        BodyMeasurementDTO(
            date: date,
            weightKg: weightKg,
            bodyFatPercentage: bodyFatPercentage,
            source: source.rawValue
        )
    }
}
