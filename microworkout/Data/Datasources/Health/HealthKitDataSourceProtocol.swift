import Foundation

protocol HealthKitDataSourceProtocol {
    func requestAuthorization() async throws -> Bool
    func fetchExerciseTimeToday() async throws -> Double?
    func fetchExerciseTime(startDate: Date, endDate: Date) async throws -> [Date: Double]?
    func fetchStepsCountToday() async throws -> Double?
    func fetchHoursStandingCount() async throws -> Double?
}
