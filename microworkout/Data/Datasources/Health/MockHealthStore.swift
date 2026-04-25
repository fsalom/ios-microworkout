import HealthKit

final class MockHealthStore: HealthStoreProtocol {
    var isHealthDataAvailable: Bool = true
    var workoutSessionMirroringStartHandler: ((HKWorkoutSession) -> Void)?

    private(set) var lastExecutedQueries: [HKQuery] = []
    private(set) var authorizationRequested: Bool = false
    private(set) var requestedToShare: Set<HKSampleType>?
    private(set) var requestedToRead: Set<HKObjectType>?

    func requestAuthorization(toShare typesToShare: Set<HKSampleType>?, read typesToRead: Set<HKObjectType>?, completion: @escaping (Bool, Error?) -> Void) {
        authorizationRequested = true
        requestedToShare = typesToShare
        requestedToRead = typesToRead
        completion(true, nil)
    }

    func authorizationStatus(for objectType: HKObjectType) -> HKAuthorizationStatus {
        .sharingAuthorized
    }

    func execute(_ query: HKQuery) {
        lastExecutedQueries.append(query)
    }
}
