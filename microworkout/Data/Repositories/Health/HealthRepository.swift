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
        do { return try await dataSource.requestAuthorization() }
        catch { throw mapHealthError(error) }
    }

    func fetchExerciseTimeToday() async throws -> Double? {
        do { return try await dataSource.fetchExerciseTimeToday() }
        catch { throw mapHealthError(error) }
    }

    func fetchExerciseTime(startDate: Date, endDate: Date) async throws -> [Date : Double]? {
        do { return try await dataSource.fetchExerciseTime(startDate: startDate, endDate: endDate) }
        catch { throw mapHealthError(error) }
    }

    func fetchStepsCountToday() async throws -> Double? {
        do { return try await dataSource.fetchStepsCountToday() }
        catch { throw mapHealthError(error) }
    }

    func fetchStepsCount(startDate: Date, endDate: Date) async throws -> [Date : Double]? {
        do { return try await dataSource.fetchStepsCount(startDate: startDate, endDate: endDate) }
        catch { throw mapHealthError(error) }
    }

    func fetchStandingTime() async throws -> Double? {
        do { return try await dataSource.fetchStandingTime() }
        catch { throw mapHealthError(error) }
    }

    func fetchStandingTime(startDate: Date, endDate: Date) async throws -> [Date : Double]? {
        do { return try await dataSource.fetchStandingTime(startDate: startDate, endDate: endDate) }
        catch { throw mapHealthError(error) }
    }

    func fetchWorkouts() async throws -> [HealthWorkout] {
        do { return try await dataSource.fetchWorkouts() }
        catch { throw mapHealthError(error) }
    }

    private func mapHealthError(_ error: Error) -> DomainError {
        if let hk = error as? HealthKitError, hk == .notAuthorized {
            return .notAuthorized
        }
        return DomainError.map(error)
    }
}
