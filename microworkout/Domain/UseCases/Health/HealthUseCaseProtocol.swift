import Foundation

protocol HealthUseCaseProtocol {
    func requestAuthorization() async throws -> Bool
    func getDaysPerWeeksWithHealthInfo(for numberOfWeeks: Int) async throws -> [[HealthDay]]
    func getHealthInfoForToday() async throws -> HealthDay
}
