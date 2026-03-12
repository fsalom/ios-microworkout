import HealthKit

protocol HealthKitManagerProtocol {
    var isHealthDataAvailable: Bool { get }
    var authorizationStatus: HKAuthorizationStatus { get }
    var store: HKHealthStore { get }

    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void)
    func fetchStepCount(completion: @escaping (Double?, Error?) -> Void)
    func fetchStepCount(startDate: Date, endDate: Date, completion: @escaping ([Date: Double]?, Error?) -> Void)
    func fetchLatestHeartRate(completion: @escaping (Double?, Error?) -> Void)
    func fetchExerciseTimeToday(completion: @escaping (Double?, Error?) -> Void)
    func fetchExerciseTime(startDate: Date, endDate: Date, completion: @escaping ([Date: Double]?, Error?) -> Void)
    func fetchStandingTime(completion: @escaping (Double?, Error?) -> Void)
    func fetchStandingTime(startDate: Date, endDate: Date, completion: @escaping ([Date: Double]?, Error?) -> Void)
    func fetchWorkouts(completion: @escaping ([HKWorkout]?, Error?) -> Void)
}
