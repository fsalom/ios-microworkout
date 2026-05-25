import HealthKit

protocol HealthKitManagerProtocol {
    var store: HealthStoreProtocol { get }
    var isHealthDataAvailable: Bool { get }
    var authorizationStatus: HKAuthorizationStatus { get }

    func requestAuthorization() async throws -> Bool

    func fetchStepCount() async throws -> Double?
    func fetchStepCount(startDate: Date, endDate: Date) async throws -> [Date: Double]?

    func fetchLatestHeartRate() async throws -> Double?

    func fetchExerciseTimeToday() async throws -> Double?
    func fetchExerciseTime(startDate: Date, endDate: Date) async throws -> [Date: Double]?

    func fetchStandingTime() async throws -> Double?
    func fetchStandingTime(startDate: Date, endDate: Date) async throws -> [Date: Double]?

    func fetchWorkouts() async throws -> [HKWorkout]
    func fetchAverageHeartRate(for workout: HKWorkout) async -> Double?
}
