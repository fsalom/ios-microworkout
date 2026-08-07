import Foundation

protocol BodyMetricsRepositoryProtocol {
    /// Serie de medidas del rango, de más antigua a más reciente.
    func getMeasurements(from start: Date, to end: Date) async throws -> [BodyMeasurement]
    /// Anota un peso. Va a Salud (que es la fuente), al dispositivo y, si hay
    /// sesión, a la cuenta.
    func saveWeight(_ kilograms: Double, on date: Date) async throws
    func delete(date: Date) async throws
    /// Cuántas medidas hay en el dispositivo o en Salud que no estén en la cuenta.
    func pendingSyncCount() async throws -> Int
    /// Sube a la cuenta lo que falte. Devuelve cuántas subió.
    func syncLocalToRemote() async throws -> Int
}
