import Foundation

class HealthRepository: HealthRepositoryProtocol {
    private var dataSource: HealthKitDataSourceProtocol!

    init(dataSource: HealthKitDataSourceProtocol){
        self.dataSource = dataSource
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

    func fetchHoursStandingCount() async throws -> Double? {
        try await dataSource.fetchHoursStandingCount()
    }
}
