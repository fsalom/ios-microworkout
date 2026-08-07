import HealthKit

protocol HealthStoreProtocol {
    var isHealthDataAvailable: Bool { get }
    var workoutSessionMirroringStartHandler: ((HKWorkoutSession) -> Void)? { get set }
    
    func requestAuthorization(
        toShare typesToShare: Set<HKSampleType>?,
        read typesToRead: Set<HKObjectType>?,
        completion: @escaping (Bool, Error?) -> Void
    )
    
    func authorizationStatus(for objectType: HKObjectType) -> HKAuthorizationStatus

    func execute(_ query: HKQuery)

    /// Escribe una muestra en Salud. Hasta ahora el store solo leía; hace falta
    /// para que el peso anotado en la app acabe en Salud y no en un historial
    /// paralelo.
    func save(_ object: HKObject) async throws
}
