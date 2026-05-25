import Foundation

/// Tipo de error de dominio expuesto por los repositorios.
///
/// Los repos traducen errores de infraestructura (red, HealthKit, decoding,
/// UserDefaults...) a uno de estos casos para que las capas superiores tengan
/// un tipo único contra el que enrutar la UI (toasts, alerts, reintentos).
enum DomainError: LocalizedError {
    case notAuthorized
    case notFound
    case network(underlying: Error)
    case decoding(underlying: Error)
    case storage(underlying: Error)
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "No tienes permisos para acceder a estos datos."
        case .notFound:
            return "No se encontró el recurso solicitado."
        case .network(let underlying):
            return "Error de red: \(underlying.localizedDescription)"
        case .decoding:
            return "El servidor devolvió una respuesta con formato inesperado."
        case .storage(let underlying):
            return "Error de almacenamiento: \(underlying.localizedDescription)"
        case .unknown(let underlying):
            return underlying.localizedDescription
        }
    }
}

extension DomainError {
    /// Mapea un error arbitrario a un caso de DomainError. Si ya es DomainError,
    /// se devuelve tal cual; si no, se intenta clasificar por tipo conocido.
    static func map(_ error: Error) -> DomainError {
        if let domain = error as? DomainError { return domain }
        if error is DecodingError { return .decoding(underlying: error) }
        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain { return .network(underlying: error) }
        return .unknown(error)
    }
}
