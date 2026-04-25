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
}
