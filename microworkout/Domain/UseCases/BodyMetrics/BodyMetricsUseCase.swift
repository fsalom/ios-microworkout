import Foundation

/// Error propio y no un caso nuevo en `DomainError`: esto no es un fallo de red,
/// de almacenamiento ni de permisos, es que el número no vale.
enum BodyMetricsError: LocalizedError, Equatable {
    case weightOutOfRange

    var errorDescription: String? {
        switch self {
        case .weightOutOfRange: return "El peso debe estar entre 20 y 400 kg."
        }
    }
}

protocol BodyMetricsUseCaseProtocol {
    /// Serie de los últimos `days` días, de más antigua a más reciente.
    func getRecent(days: Int) async throws -> [BodyMeasurement]
    func saveWeight(_ kilograms: Double, on date: Date) async throws
    func delete(date: Date) async throws
    /// Último peso conocido, para rellenar el campo al anotar.
    func latestWeight() async throws -> Double?
}

final class BodyMetricsUseCase: BodyMetricsUseCaseProtocol {
    /// Rango que se muestra por defecto. Tres meses: suficiente para que una
    /// tendencia de peso real se vea, y corto para que el ruido diario no la tape.
    static let defaultWindowDays = 90

    private let repository: BodyMetricsRepositoryProtocol

    init(repository: BodyMetricsRepositoryProtocol) {
        self.repository = repository
    }

    func getRecent(days: Int = defaultWindowDays) async throws -> [BodyMeasurement] {
        let end = Date()
        let start = Calendar.current.date(byAdding: .day, value: -days, to: end) ?? end
        return try await repository.getMeasurements(from: start, to: end)
    }

    func saveWeight(_ kilograms: Double, on date: Date) async throws {
        // Rango de cordura: teclear 8 en vez de 80 no debe entrar en la serie ni,
        // sobre todo, escribirse en Salud, de donde no lo borramos nosotros.
        guard kilograms > 20, kilograms < 400 else { throw BodyMetricsError.weightOutOfRange }
        try await repository.saveWeight(kilograms, on: date)
    }

    func delete(date: Date) async throws {
        try await repository.delete(date: date)
    }

    func latestWeight() async throws -> Double? {
        try await getRecent(days: 365).last(where: { $0.weightKg != nil })?.weightKg
    }
}
