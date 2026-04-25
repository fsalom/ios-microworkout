import HealthKit

final class HealthKitStore: HealthStoreProtocol {
    private let store = HKHealthStore()
    var workoutSessionMirroringStartHandler: ((HKWorkoutSession) -> Void)?
    var isHealthDataAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    func requestAuthorization(toShare typesToShare: Set<HKSampleType>?, read typesToRead: Set<HKObjectType>?, completion: @escaping (Bool, Error?) -> Void) {
        store.requestAuthorization(toShare: typesToShare, read: typesToRead, completion: completion)
    }

    func authorizationStatus(for objectType: HKObjectType) -> HKAuthorizationStatus {
        store.authorizationStatus(for: objectType)
    }
    
    func execute(_ query: HKQuery) {
        store.execute(query)
    }
}
