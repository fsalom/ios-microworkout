import Foundation

protocol HealthKitDataSourceProtocol {
    var isHealthDataAvailable: Bool { get }
    var authorizationStatus: HealthAuthorizationStatus { get }
    func requestAuthorization() async throws -> Bool
    func fetchExerciseTimeToday() async throws -> Double?
    func fetchExerciseTime(startDate: Date, endDate: Date) async throws -> [Date: Double]?
    func fetchStepsCountToday() async throws -> Double?
    func fetchStepsCount(startDate: Date, endDate: Date) async throws -> [Date: Double]?
    func fetchStandingTime() async throws -> Double?
    func fetchStandingTime(startDate: Date, endDate: Date) async throws -> [Date: Double]?
    func fetchWorkouts() async throws -> [HealthWorkout]
}
