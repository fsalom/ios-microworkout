import Foundation

class HealthRepository: HealthRepositoryProtocol {
    private var dataSource: HealthKitDataSourceProtocol!

    init(dataSource: HealthKitDataSourceProtocol){
        self.dataSource = dataSource
    }

    var isHealthDataAvailable: Bool {
        dataSource.isHealthDataAvailable
    }

    var authorizationStatus: HealthAuthorizationStatus {
        dataSource.authorizationStatus
    }

    func requestAuthorization() async throws -> Bool {
        try await dataSource.requestAuthorization()
    }

    func fetchExerciseTimeToday() async throws -> Double? {
        try await dataSource.fetchExerciseTimeToday()
    }

    func fetchExerciseTime(startDate: Date, endDate: Date) async throws -> [Date : Double]? {
        try await dataSource.fetchExerciseTime(startDate: startDate, endDate: endDate)
    }
    
    func fetchStepsCountToday() async throws -> Double? {
        try await dataSource.fetchStepsCountToday()
    }

    func fetchStepsCount(startDate: Date, endDate: Date) async throws -> [Date : Double]? {
        try await dataSource.fetchStepsCount(startDate: startDate, endDate: endDate)
    }

    func fetchStandingTime() async throws -> Double? {
        try await dataSource.fetchStandingTime()
    }

    func fetchStandingTime(startDate: Date, endDate: Date) async throws -> [Date : Double]? {
        try await dataSource.fetchStandingTime(startDate: startDate, endDate: endDate)
    }
}
