import Foundation

protocol BodyMetricsLocalDataSourceProtocol {
    func getAll() -> [DailyMetricsDTO]
    func save(_ measurement: DailyMetricsDTO)
    func delete(date: Date)
    /// Días que el usuario borró explícitamente, normalizados al inicio del día.
    func deletedDates() -> Set<Date>
}

/// Copia en el dispositivo de las medidas.
///
/// Salud es la fuente, pero puede no estar: si el usuario no da permiso, o el
/// dispositivo no tiene HealthKit, lo que anote tiene que quedarse en algún sitio.
/// Además es lo que la sincronización sube a la cuenta cuando el servidor falla.
final class BodyMetricsLocalDataSource: BodyMetricsLocalDataSourceProtocol {
    private let storage: UserDefaultsManagerProtocol
    private let key = "bodyMetrics.measurements"
    private let deletedKey = "bodyMetrics.deletedDates"

    init(storage: UserDefaultsManagerProtocol) {
        self.storage = storage
    }

    func getAll() -> [DailyMetricsDTO] {
        storage.get(forKey: key) ?? []
    }

    func save(_ measurement: DailyMetricsDTO) {
        var all: [DailyMetricsDTO] = storage.get(forKey: key) ?? []
        // Una por día: la clave es el día, igual que en el servidor y en Salud.
        all.removeAll { Calendar.current.isDate($0.date, inSameDayAs: measurement.date) }
        all.append(measurement)
        storage.save(all, forKey: key)
        // Volver a anotar un día levanta su lápida: si no, el usuario borra el
        // martes, se pesa otra vez el martes y su peso no aparece por ningún lado.
        setDeleted(removing: measurement.date)
    }

    /// Borrado con lápida.
    ///
    /// Quitar la fila de aquí no basta: Apple Salud sigue teniendo la muestra (la
    /// escribió la báscula, u otra app, o esta misma al anotar el peso) y la
    /// siguiente lectura la traería de vuelta. Se recuerda QUÉ días borró el
    /// usuario para poder filtrarlos después.
    func delete(date: Date) {
        var all: [DailyMetricsDTO] = storage.get(forKey: key) ?? []
        all.removeAll { Calendar.current.isDate($0.date, inSameDayAs: date) }
        storage.save(all, forKey: key)
        setDeleted(adding: date)
    }

    func deletedDates() -> Set<Date> {
        Set((storage.get(forKey: deletedKey) ?? [Date]()).map(Calendar.current.startOfDay(for:)))
    }

    private func setDeleted(adding date: Date) {
        var dates = deletedDates()
        dates.insert(Calendar.current.startOfDay(for: date))
        storage.save(Array(dates), forKey: deletedKey)
    }

    private func setDeleted(removing date: Date) {
        var dates = deletedDates()
        guard dates.remove(Calendar.current.startOfDay(for: date)) != nil else { return }
        storage.save(Array(dates), forKey: deletedKey)
    }
}

struct DailyMetricsDTO: Codable {
    var date: Date
    var weightKg: Double?
    var bodyFatPercentage: Double?
    var steps: Int?
    var activeKcal: Double?
    var exerciseMinutes: Double?
    var standingMinutes: Double?
    var restingHeartRate: Double?
    var source: String

    func toDomain() -> DailyMetrics {
        DailyMetrics(
            date: date,
            weightKg: weightKg,
            bodyFatPercentage: bodyFatPercentage,
            steps: steps,
            activeKcal: activeKcal,
            exerciseMinutes: exerciseMinutes,
            standingMinutes: standingMinutes,
            restingHeartRate: restingHeartRate,
            source: MeasurementSource(rawValue: source) ?? .manual
        )
    }
}

extension DailyMetrics {
    func toDTO() -> DailyMetricsDTO {
        DailyMetricsDTO(
            date: date,
            weightKg: weightKg,
            bodyFatPercentage: bodyFatPercentage,
            steps: steps,
            activeKcal: activeKcal,
            exerciseMinutes: exerciseMinutes,
            standingMinutes: standingMinutes,
            restingHeartRate: restingHeartRate,
            source: source.rawValue
        )
    }
}
