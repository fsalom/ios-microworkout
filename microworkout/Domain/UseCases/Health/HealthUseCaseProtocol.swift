import Foundation

protocol HealthUseCaseProtocol {
    func requestAuthorization() async throws -> Bool
    func fetchExerciseTimeToday() async throws -> Double?
    func fetchExerciseTime(startDate: Date, endDate: Date) async throws -> [Date: Double]
    func getDaysPerWeeksWithHealthInfo(for numberOfWeeks: Int) async throws -> [[HealthDay]]
}
