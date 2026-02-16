import Foundation

enum HealthAuthorizationStatus {
    case notDetermined
    case authorized
    case denied
}

protocol HealthUseCaseProtocol {
    var isHealthDataAvailable: Bool { get }
    var authorizationStatus: HealthAuthorizationStatus { get }
    func requestAuthorization() async throws -> Bool
    func getDaysPerWeeksWithHealthInfo(for numberOfWeeks: Int) async throws -> [[HealthDay]]
    func getHealthInfoForToday() async throws -> HealthDay
}
